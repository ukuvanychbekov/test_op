import { waitForElement } from 'core-app/core/setup/globals/onboarding/helpers';
import { OnboardingStep } from 'core-app/core/setup/globals/onboarding/onboarding_tour';

export function wpOnboardingTourSteps():OnboardingStep[] {
  return [
    {
      'next .wp-table--row': I18n.t('js.onboarding.steps.wp.list'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      onNext() {
        jQuery('.inline-edit--display-field.id a ')[0].click();
      },
    },
    {
      'next .work-packages-full-view--split-left': I18n.t('js.onboarding.steps.wp.full_view'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      containerClass: '-dark -hidden-arrow',
    },
    {
      'next .work-packages-back-button': I18n.t('js.onboarding.steps.wp.back_button'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      onNext() {
        jQuery('.work-packages-back-button')[0].click();
      },
    },
    {
      'next .add-work-package': I18n.t('js.onboarding.steps.wp.create_button'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      shape: 'circle',
      timeout: () => new Promise((resolve) => {
        // We are waiting here for the badge to appear,
        // because its the last that appears and it shifts the WP create button to the left.
        // Thus it is important that the tour rendering starts after the badge is visible
        waitForElement('#work-packages-filter-toggle-button .badge', '#content', () => {
          resolve(undefined);
        });
      }),
      onNext() {
        jQuery('#wp-view-toggle-button').click();
      },
    },
    {
      'next #wp-view-toggle-button': I18n.t('js.onboarding.steps.wp.timeline_button'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      bottom: '-64',
      onNext() {
        jQuery('#wp-view-context-menu .icon-view-timeline')[0].click();
      },
    },
    {
      'next .work-packages-tabletimeline--timeline-side': I18n.t('js.onboarding.steps.wp.timeline'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      containerClass: '-dark -hidden-arrow',
    },
    {
      'next .main-menu--arrow-left-to-project': I18n.t('js.onboarding.steps.sidebar_arrow'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      onNext() {
        jQuery('.main-menu--arrow-left-to-project')[0].click();
      },
    },
  ];
}
