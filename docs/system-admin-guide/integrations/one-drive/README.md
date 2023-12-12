---
sidebar_navigation:
  title: OneDrive/SharePoint integration setup
  priority: 601
description: Set up One Drive as a file storage in your OpenProject instance
keywords: One Drive, SharePoint, file storage, integration
---

# OneDrive/SharePoint (Enterprise add-on) integration setup

| Topic                                                                                   | Description                                                               |
|-----------------------------------------------------------------------------------------|:--------------------------------------------------------------------------|
| [Minimum requirements](#minimum-requirements)                                           | Minimum version requirements to enable the integration                    |
| [Set up the integration](#set-up-the-integration)                                       | Connect OpenProject and OneDrive/SharePoint instances as an administrator |
| [Drive ID guide](./drive-id-guide)                                                      | How to obtain a drive ID                                                  |
| [Using the integration](#using-the-integration)                                         | How to use the OneDrive/SharePoint integration                            |
| [Edit a OneDrive/SharePoint file storage](#edit-a-onedrivesharepoint-file-storage)      | Edit a OneDrive/SharePoint file storage                                   |
| [Delete an OneDrive/SharePoint file storage](#delete-a-onedrivesharepoint-file-storage) | Delete a OneDrive/SharePoint file storage                                 |

> **Note**: OneDrive/SharePoint integration is an Enterprise add-on and can only be used
> with [Enterprise cloud](../../../enterprise-guide/enterprise-cloud-guide/)
> or [Enterprise on-premises](../../../enterprise-guide/enterprise-on-premises-guide/). An upgrade from the free
> Community
> edition is easy and helps support OpenProject.

OpenProject offers an integration with OneDrive/SharePoint to allow users to:

- Link files and folders stored in OneDrive/SharePoint with OpenProject work packages
- View, open and download files and folder linked to a work package via the Files tab

> Note: This guide only covers the integration setup. Please go to
> our [OneDrive/SharePoint integration user guide](../../../user-guide/file-management/nextcloud-integration/) to learn
> more about how to work with the OneDrive/SharePoint integration.

## Minimum requirements

Please note these minimum version requirements for the integration to work with a minimal feature set:

- OpenProject version 13.1 (or above)
- Access to OneDrive/SharePoint

We recommend using the latest versions of both OneDrive/SharePoint and OpenProject to be able to use the latest
features.

## Set up the integration

> **Important**: You need administrator privileges in the Azure portal for your Microsoft Entra ID and in your
> OpenProject instance to set up this integration.

Navigate to **System administration -> File storages**. You will see the list of all storages that have already been set
up. If no files storages have been set up yet, a banner will tell you that there are no storages yet set up.

Click the green **+Storage** button and select the OneDrive/SharePoint option.

![Add a new OneDrive/SharePoint storage to OpenProject](openproject_system_guide_new_onedrive_storage.png)

A screen will open, in which you will need to add the following details for your new OneDrive/SharePoint storage. Please
consult your Azure administrator and the [Drive ID guide](./drive-id-guide) to obtain respective information. Be aware,
that the last step includes copying generated information to the Azure portal.

![Setting up a new OneDrive/SharePoint](openproject_system_guide_new_onedrive_storage_details.png)

## Using the integration

Once the [file storage is added and enabled for projects](../../../user-guide/projects/project-settings/file-storages),
your users are able to take full advantage of the integration between OneDrive/SharePoint and OpenProject. For more
information on how to link SharePoint files to work packages in OpenProject, please refer to
the [OneDrive/SharePoint integration user guide](../../../user-guide/file-management/one-drive-integration).

## Edit a OneDrive/SharePoint file storage

To edit an existing OneDrive/SharePoint file storage hover over the name of the storage you want to edit and click it.

![Select OneDrive/SharePoint file storage in OpenProject system administration](openproject_system_guide_select_onedrive_storage.png)

To update the general storage information, click the **Edit** icon next to the storage provider. To replace the Azure
authentication information, click on the **Sync** icon next to the OAuth application. With changing the authentication
information the redirect URI will get generated again and thus needs to be copied again. The redirect URI can be copied
by clicking on the **Copy-to-Clipboard** element next to the information text, or by entering the form by clicking the
**View** icon.

![Edit OneDrive/SharePoint in OpenProject](openproject_system_guide_edit_icon_onedrive_storage.png)

Here you will be able to edit all of the information you have specified when creating the OneDrive/SharePoint connection
initially.

## Delete a OneDrive/SharePoint file storage

You can delete a OneDrive/SharePoint file storage either at a project level or at an instance-level.

Deleting a file storage at a project level simply makes it unavailable to that particular project, without affecting the
integration for other projects. Project admins can do so by navigating to **Project settings -> File storages** and
clicking the **Delete** icon next to the file storage you would like to remove.

![Delete a OneDrive/SharePoint storage from an OpenProject project](openproject_system_guide_delete_onedrive_storage_in_a_project.png)

Deleting a file storage at an instance level deletes the OneDrive/SharePoint integration completely, making it
inaccessible to all projects in that instance. Should an instance administrator nevertheless want to do so, they can
navigate to **Administration -> File storages**, hover over the name of the file storage they want to remove and click
it to enter the next page. Then they need to click the **Delete** button in the top right corner.

![Delete icon for SharePoint integration in OpenProject system settings](openproject_system_guide_delete_icon_onedrive_storage.png)

You will be asked to confirm the exact file storage name.

![Delete a SharePoint integration from OpenProject system settings](openproject_system_guide_delete_onedrive_storage.png)

> **Important:** Deleting a file storage as an instance administrator will also delete all settings and links between
> work packages and OneDrive/SharePoint files/folders. This means that should you want to reconnect your
> OneDrive/SharePoint instance with OpenProject, you will need complete the entire setup process once again.

## Getting support

If you run into any issues or you cannot setup your integration yourself please use
our [Support Installation & Updates forum](https://community.openproject.org/projects/openproject/forums/9) or if you
have an Enterprise subscription, please contact us at Enterprise Support.
