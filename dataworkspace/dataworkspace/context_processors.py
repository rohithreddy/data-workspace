from django.conf import settings


def common(request):
    # Ready to add a permissions check. Note: after putting an initial permissions
    # check here, we did occasionally run out of database connections and use
    # 100% CPU on the server. There was some evidence that an exception here
    # caused some sort of infinite loop rending the 500 error page, which caused
    # this function to be called, which then caused another exception...
    #
    # Not sure of cause/effect, but out of paranoia, decided to remove the
    # database query.
    can_see_visualisations_tab = False

    return {
        'root_href': f'{request.scheme}://{settings.APPLICATION_ROOT_DOMAIN}/',
        'google_analytics_site_id': settings.GOOGLE_ANALYTICS_SITE_ID,
        'can_see_visualisations_tab': can_see_visualisations_tab,
        'gtm_container_id': settings.GTM_CONTAINER_ID,
        'gtm_container_environment_params': settings.GTM_CONTAINER_ENVIRONMENT_PARAMS,
    }
