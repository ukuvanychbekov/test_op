---
sidebar_navigation:
  title: Dynamic meetings
  priority: 800
description: Manage meetings with agenda and meeting minutes in OpenProject.
keywords: meetings, dynamic meetings, agenda, minutes
---

# Dynamic meetings management

Introduced in OpenProject 13.1, dynamic meetings offer easier meeting management, improved agenda creation and the ability to link work packages to meetings and vice-versa. 

> **Note:** The **Meetings module needs to be activated** in the [Project Settings](../../projects/project-settings/modules/) to be able to create and edit meetings.


| Topic                                                        | Content                                           |
| ------------------------------------------------------------ | ------------------------------------------------- |
| [Meetings in OpenProject](#meetings-in-openproject)          | How to open meetings in OpenProject.              |
| [Create a new meeting](#create-a-new-meeting)                | How to create a new meeting in OpenProject.       |
| [Edit a meeting](#edit-a-meeting)                            | How to edit an existing meeting.                  |
| [Add a work package to the agenda](#add-a-work-package-to-the-agenda) | How to add a work package to a meeting agenda.    |
| [Create or edit the meeting agenda](#create-or-edit-the-meeting-agenda) | How to create or edit the agenda.                 |
| [Add meeting participants](#add-meeting-participants)        | How to invite people to a meeting.                |
| [Send email to all participants](#send-email-to-all-participants) | How to send an email to all meeting participants. |
| [Download a meeting as an iCalendar event](#download-a-meeting-as-an-icalendar-event) | How to download a meeting as an iCalendar event.  |
| [Close a meeting](#close-a-meeting)                          | How to close a meeting in OpenProject.            |
| [Re-open a meeting](#re-open-a-meeting)                      | How to re-open a meeting in OpenProject.          |
| [Delete a meeting](#delete-a-meeting)                        | How to delete a meeting in OpenProject.           |

## Meetings in OpenProject

By selecting **Meetings** in the project menu on the left, you get an overview of all the meetings within a specific project sorted by date. By clicking on a meeting name you can view further details of the meeting.

To get an overview of the meetings across multiple projects, you can select **Meetings** in the [global modules menu](https://www.openproject.org/docs/user-guide/home/global-modules/).

![Select meetings module from openproject global modules ](openproject_userguide_meetings_module_select.png)

The menu on the left will allow you to filter for upcoming or past meetings. You can also filter the list of the meetings based on your involvement. 

![Meetings overview in openproject global modules](openproject_userguide_dynamic_meetings_overview.png)

## Create and edit dynamic meetings
### Create a new meeting

You can either create a meeting from within a project or from the global **Meetings** module. 

> *Note:* Dynamic meetings were introduced in OpenProject 13.1. At the moment, the Meetings module lets you create [classic](../classic-meetings) or dynamic meetings but please keep in mind that the ability to create [classic meetings](../classic-meetings) will eventually be removed from OpenProject.

To create a new meeting, click the green **+ Meeting** button in the upper right corner.

![Create new meeting in OpenProject](openproject_userguide_create_new_meeting.png)

Enter your meeting's title, type, location, start date and duration.

If you are creating a meeting from a global module you will first need to select a project to which the meeting is attributed. After you have selected a project, the list of potential participants (project members) will appear for you to select who to invite. After the meeting you can note who attended the meeting.

Click the blue **Create** button to save your changes.

### Edit a meeting

If you want to change the details of a meeting, for example its time or location, open the meetings details view by clicking on pencil icon next to the **Meeting details**. 

![edit-meeting](openproject_userguide_edit_dynamic_meeting.png)

An edit screen will be displayed, where you can adjust the date, time, duration and location of the meeting.


![edit-meeting](openproject_userguide_edit_screen.png)

Do not forget to save the changes by clicking the green **Save** button. Cancel will bring you back to the details view.

In order to edit the title of the meeting select the dropdown menu behind the three dots and select the **Edit meeting title**.

![Edit a meeting title in OpenProject](openproject_userguid_dynamic_meeting_edit_title.png)


### Create or edit the meeting agenda

After creating a meeting, you can set up a **meeting agenda**.

You can add items to an agenda or directly link to existing work packages by selecting the desired option under the green **Add** button. 

![The add button with two choices: agenda item or work package](openproject_dynamic_meetings_add_agenda_item.png)

After you have finalized the agenda, you can always edit the agenda items, add notes, move an item up or down or delete it. Clicking on the three dots on the right edge of each agenda item will display a menu with these options.

![Edit agenda in OpenProject dynamic meetings](openproject_dynamic_meetings_edit_agenda.png)

You may also re-order agenda items by clicking on the drag handle (the icon with six dots) on the left edge of each agenda item and dragging that item above or below.

![Drag handle next to an agenda item](agenda_drag_handle.png)

The durations of each agenda item are automatically summed up. If that sum exceeds the planned duration entered in *Meeting Details*, the duration of those agenda times that exceed the planned duration will appear in red to warn you of the fact.

![OpenProject meeting too long](openproject_dynamic_meetings_agenda_too_long.png)

### Add a work package to the agenda

There are two ways to add a work package to a work package agenda. 

- **From the Meetings module**: using the **+ Add** button [add a work package agenda item](#create-or-edit-the-meeting-agenda) or
- **From a particular work package**: using the **+ Add to meeting** button on the [**Meetings** tab](../../work-packages/add-work-packages-to-meetings)

You can add a work package to both upcoming or past meetings as long as the work package is marked **open**. 

![OpenProject work packages in meetings agenda](openproject_dynamic_meetings_wp_agenda.png)

## Meeting participants
### Add meeting participants

You will see the list of all the invited project members under **Participants**. You can **add participants** (Invitees and Attendees) to a meeting in [edit mode](#edit-a-meeting). The process is the same whether you are creating a new meeting or editing an existing one. 

![adding meeting participants](openproject_dynamic_meetings_add_participants.png)

You will see the list of all the project members and be able to tell, based on the check marks next to the name under the *Invited* column, who was invited. After the meeting, you can record who actually took part using the checkmarks under the Attended column. 

![invite meeting participants](openproject_dynamic_meetings_add_new_participants.png)

To remove an invited project member from a meeting, simply uncheck both check marks.

Click on the **Save** button to confirm the changes.

### Send email to all participants

You can send an email reminder to all the meeting participants. Select the dropdown by clicking on the three dots in the top right corner and select **Send email to all participants**. An email reminder with the meeting details (including a link to the meeting) is immediately sent to all invitees and attendees.

## Download a meeting as an iCalendar event

You can download a meeting as an iCalendar event. Select the dropdown by clicking on the three dots in the top right corner and select the **Download iCalendar event**.

Read more about [subscribing to a calendar](../../calendar/#subscribe-to-a-calendar).

## Close a meeting

Clicking on the **Close meeting** after the meeting is completed with lock the current state and make render it read-only. 

![](openproject_userguide_close_meeting.png)

## Re-open a meeting

Once a meeting has been closed, it can no longer be edited. Project members with the permission to edit and close meetings will, however, see a **Re-open meeting** option. Clicking on this re-opens a meeting and allows further editing.

![Re-open a meeting in OpenProject](openproject_dynmic_meetings_reopen_meeting.png)

## Delete a meeting

You can delete a meeting. To do so, click on the three dots in the top right corner, select **Delete meeting** and confirm your choice.

![Deleting a dynamic meeting in OpenProject](openproject_dynamic_meetings_delete_meeting.png)
