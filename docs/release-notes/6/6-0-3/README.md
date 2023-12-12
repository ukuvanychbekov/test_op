---
  title: OpenProject 6.0.3
  sidebar_navigation:
      title: 6.0.3
  release_version: 6.0.3
  release_date: 2016-08-16
---

# OpenProject 6.0.3

OpenProject 6.0.3 contains an important security fix. It upgrades the
Rails version to 4.2.7.1 to address the following
CVEs:

[CVE-2016-6317](https://groups.google.com/forum/#!topic/ruby-security-ann/WccgKSKiPZA)  
[CVE-2016-6316](https://groups.google.com/forum/#!topic/ruby-security-ann/8B2iV2tPRSE)

**The following bugs have been fixed in OpenProject 6.0.3:**

  - The help and profile dropdown changed rapidly when hovering over
    them ([#23745](https://community.openproject.com/wp/23745)).
  - Safari did not display the pagination buttons on the work package
    page
    ([#23785](https://community.openproject.com/wp/23785)).
  - The projects-menu did not properly display all projects in some
    cases
    ([#23774](https://community.openproject.com/wp/23774)).
  - Several design errors have been fixes
    ([#23778](https://community.openproject.com/wp/23778),
    [#23801](https://community.openproject.com/wp/23801)).
  - Additionally, the performance on the work package page has been
    slightly improved
    ([#23781](https://community.openproject.com/wp/23781)).

We strongly recommend the upgrade.

Thanks a lot to the community, in particular to Mikhail Podshivalin,
Frank Schmid and Marc Vollmer, for [reporting multiple
bugs](../../../development/report-a-bug/)!

For further information on the release, please refer to the  
[Changelog v.6.0.3](https://community.openproject.com/versions/815) 
or take a look at
[GitHub](https://github.com/opf/openproject/tree/v6.0.3).


