import uuid

from django.db import models, transaction
from django.contrib.auth import get_user_model
from django.core.validators import RegexValidator

from dataworkspace.apps.core.models import Database, TimeStampedModel
from dataworkspace.apps.eventlog.models import EventLog
from dataworkspace.apps.eventlog.utils import log_event


class ApplicationTemplate(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    name = models.CharField(
        validators=[RegexValidator(regex=r'^[a-z]+$')],
        max_length=128,
        blank=False,
        help_text='Used in URLs: only lowercase letters allowed',
        unique=False,
    )
    visible = models.BooleanField(
        default=True,
        null=False,
        help_text=(
            "For tools, whether this appears on the Tools page. "
            "For visualisations, whether it's accessible at its production URL."
        ),
    )
    wrap = models.CharField(
        max_length=128,
        choices=(
            ('NONE', 'No wrapping'),
            ('FULL_HEIGHT_IFRAME', 'Wrapped in full height iframe'),
        ),
        default='NONE',
    )

    # We expect lots of visualisations with fixed hosts, so we use a undex to ensure
    # that lookups from hostname to application templates are fast...
    host_basename = models.CharField(
        max_length=128, blank=False, null=False, unique=True
    )

    nice_name = models.CharField(
        verbose_name='application', max_length=128, blank=False, unique=False
    )
    spawner = models.CharField(
        max_length=10,
        choices=(('PROCESS', 'Process'), ('FARGATE', 'Fargate')),
        default='FARGATE',
    )
    spawner_time = models.IntegerField(null=False)
    spawner_options = models.CharField(
        max_length=10240,
        help_text='Options that the spawner understands to start the application',
    )
    application_type = models.CharField(
        max_length=64,
        choices=(
            (
                'VISUALISATION',
                'Visualisation: One instance launched and accessed by all authorized users',
            ),
            ('TOOL', 'Tool: A separate instance launched for each user'),
        ),
        default='TOOL',
    )
    user_access_type = models.CharField(
        max_length=64,
        choices=(
            ('REQUIRES_AUTHENTICATION', 'Requires authentication'),
            ('REQUIRES_AUTHORIZATION', 'Requires authorization'),
        ),
        default='REQUIRES_AUTHENTICATION',
    )
    gitlab_project_id = models.IntegerField(
        null=True,
        unique=True,
        help_text='The ID of the corresponding project in GitLab',
    )

    class Meta:
        db_table = 'app_applicationtemplate'
        indexes = [
            models.Index(fields=['application_type']),
            models.Index(fields=['name']),
            models.Index(fields=['host_basename']),
        ]

    def __str__(self):
        return self.nice_name

    def user_has_access(self, user):
        return (
            self.user_access_type == 'REQUIRES_AUTHENTICATION'
            or self.applicationtemplateuserpermission_set.filter(user=user).exists()
        )


class ToolTemplate(ApplicationTemplate):
    class Meta:
        proxy = True
        verbose_name = 'Tool'

    def save(
        self, force_insert=False, force_update=False, using=None, update_fields=None
    ):
        self.application_type = 'TOOL'

        super(ToolTemplate, self).save(force_insert, force_update, using, update_fields)


class VisualisationTemplate(ApplicationTemplate):
    class Meta:
        proxy = True
        verbose_name = 'Visualisation'

    def save(
        self, force_insert=False, force_update=False, using=None, update_fields=None
    ):
        self.application_type = 'VISUALISATION'

        super(VisualisationTemplate, self).save(
            force_insert, force_update, using, update_fields
        )


class VisualisationApproval(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    approved = models.BooleanField(default=True)
    approver = models.ForeignKey(get_user_model(), on_delete=models.PROTECT)
    visualisation = models.ForeignKey(VisualisationTemplate, on_delete=models.CASCADE)

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._initial_approved = self.approved

    @transaction.atomic
    def save(
        self, force_insert=False, force_update=False, using=None, update_fields=None
    ):
        if self._initial_approved is False and self.approved is True:
            raise ValueError(
                "A new record must be created for a new approval - you cannot flip a rescinded approval."
            )
        elif self._initial_approved is self.approved and self.modified_date is not None:
            raise ValueError(
                "The only change that can be made to an approval is to unapprove it."
            )

        super().save(force_insert, force_update, using, update_fields)

        if self.approved:
            log_event(
                self.approver, EventLog.TYPE_VISUALISATION_APPROVED, related_object=self
            )
        else:
            log_event(
                self.approver,
                EventLog.TYPE_VISUALISATION_UNAPPROVED,
                related_object=self,
            )
        self._initial_approved = self.approved


class ApplicationInstance(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    owner = models.ForeignKey(get_user_model(), on_delete=models.PROTECT)

    # Stored explicitly to allow matching if URL scheme changed
    public_host = models.CharField(
        max_length=63,
        help_text='The leftmost part of the domain name of this application',
    )

    # Copy of the options to allow for spawners to be changed after (or during) spawning
    application_template = models.ForeignKey(
        ApplicationTemplate, on_delete=models.PROTECT
    )
    spawner = models.CharField(
        max_length=15, help_text='The spawner used to start the application'
    )
    spawner_application_template_options = models.CharField(
        max_length=10240,
        help_text='The spawner options at the time the application instance was spawned',
    )

    spawner_application_instance_id = models.CharField(
        max_length=128,
        help_text='An ID that the spawner understands to control and report on the application',
    )

    # As reported by the spawner
    spawner_created_at = models.DateTimeField(null=True)
    spawner_stopped_at = models.DateTimeField(null=True)
    spawner_cpu = models.CharField(max_length=16, null=True)
    spawner_memory = models.CharField(max_length=16, null=True)

    state = models.CharField(
        max_length=16,
        choices=(
            ('SPAWNING', 'Spawning'),
            ('RUNNING', 'Running'),
            ('STOPPED', 'Stopped'),
        ),
        default='SPAWNING',
    )
    proxy_url = models.CharField(
        max_length=256,
        help_text='The URL that the proxy can proxy HTTP and WebSockets requests to',
    )

    # Fargate expects numerical values for CPU and memory, but boto3 expects
    # them passed as strings. Since these ultimately come as strings from the
    # user, we keep type transformations to a minimum while maintaining
    # flexibility. Fargate will error at runtime if passed something it
    # doesn't understand, so we still get runtime errors even through this is
    # stringly-typed.
    cpu = models.CharField(max_length=16, null=True)  # if not specified by the user
    memory = models.CharField(max_length=16, null=True)  # if not specified by the user

    # The purpose of this field is to raise an IntegrityError if multiple running or spawning
    # instances for the same public host name are created, but to allow multiple stopped or
    # errored
    single_running_or_spawning_integrity = models.CharField(
        max_length=63,
        unique=True,
        help_text='Used internally to avoid duplicate running applications',
    )

    commit_id = models.CharField(null=True, max_length=8)

    class Meta:
        db_table = 'app_applicationinstance'
        indexes = [
            models.Index(fields=['created_date']),
            models.Index(fields=['owner', 'created_date']),
            models.Index(fields=['public_host', 'state']),
        ]
        permissions = [
            ('start_all_applications', 'Can start all applications'),
            ('develop_visualisations', 'Can develop visualisations'),
            ('access_appstream', 'Can access appstream'),
        ]

    def __str__(self):
        return f'{self.owner} / {self.public_host} / {self.state}'


class ApplicationInstanceDbUsers(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    db = models.ForeignKey(Database, on_delete=models.CASCADE)
    db_username = models.CharField(max_length=256)
    application_instance = models.ForeignKey(
        ApplicationInstance, on_delete=models.CASCADE
    )

    class Meta:
        indexes = [models.Index(fields=['db_username'])]


class ApplicationTemplateUserPermission(models.Model):
    user = models.ForeignKey(get_user_model(), on_delete=models.CASCADE)
    application_template = models.ForeignKey(
        ApplicationTemplate, on_delete=models.CASCADE
    )

    class Meta:
        db_table = 'app_applicationtemplateuserpermission'
        unique_together = ('user', 'application_template')


class ApplicationInstanceReport(ApplicationInstance):
    class Meta:
        proxy = True
        verbose_name = 'Application report'
        verbose_name_plural = 'Application report'
