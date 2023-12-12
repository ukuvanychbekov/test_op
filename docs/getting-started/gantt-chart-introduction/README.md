---
sidebar_navigation:
  title: Gantt charts introduction
  priority: 600
description: Introduction to Gantt charts to OpenProject.
keywords: Gantt charts introduction
---

# Introduction to Gantt charts

In this document you will get a first introduction to the Gantt charts in OpenProject, i.e. to create and manage a project plan.

<div class="glossary">
**Gantt charts** in OpenProject are defined as a type of bar chart that shows all the tasks constituting a project. The tasks are listed vertically, with the horizontal axis indicating the time. The length of the task bars is adjusted to the duration of the task.
</div>

To find out more about the functionalities for Gantt charts, please visit our [user guide for Gantt charts](../../user-guide/gantt-chart).

| Feature                                                    | Documentation for                                    |
|------------------------------------------------------------|------------------------------------------------------|
| [What is a Gantt chart?](#what-is-a-gantt-chart)           | Find out what is a Gantt chart in OpenProject.       |
| [Activate the Gantt chart](#activate-the-gantt-chart-view) | How to activate the Gantt chart view in OpenProject. |
| [Create a project plan](#create-a-project-plan)            | How to create a project plan with the Gantt charts.  |
| [Edit a project plan](#edit-a-project-plan)                | How to edit a project plan in OpenProject.           |

<video src="https://openproject-docs.s3.eu-central-1.amazonaws.com/videos/OpenProject-Project-Plan-and-Timelines-Gantt-charts.mp4" type="video/mp4" controls="" style="width:100%"></video>

## What is a Gantt chart?

With Gantt charts in OpenProject you can create and manage a project plan and share the information with your team. You can schedule your tasks and visualize the required steps to complete your project. As a project manager you are directly informed about delays in your project and can act accordingly.

The dynamic Gantt chart in OpenProject displays the phases, tasks and milestones in your project as well as relationships between them. The elements for phases and tasks each have a start and end date, so you are always informed about the current status. The milestone only appears as a fixed point in time.

## Activate the Gantt chart view

To open the Gantt chart view in OpenProject, the [work packages module needs to be activated](../../user-guide/activity) in the project settings.

Within your project menu, navigate to the work packages module. Select the **Gantt chart view** in the work package table with the button on the top right.

![open the gantt chart view](gantt-chart-view.png)

You can activate a Gantt chart view from any work package table (or saved query) by selecting the Gantt view from the top.

The Gantt chart then displays all work package types, e.g. phases and milestones, tasks or bugs, in a timeline view.

It shows dependencies between different work packages as well as additional information, e.g. subject, start or due dates.

## Create a project plan

To create a project plan in OpenProject, switch to the work package table and select the [Gantt chart view](#activate-the-gantt-chart-view).

You can create new work package directly in the table by clicking on the **create new work package** link at the bottom of the table. You can change the work package type or other attributes directly in the table view.

Click in the at the level of the line of the work package you want to map in the Gantt chart to add an element in the project plan. 

You can change the duration or move the element in the project plan via drag and drop.

![create projectplan](create-projectplan-1571743591204.gif)

## Edit a project plan

You can edit a project plan by clicking directly in the table and changing work package attributes, e.g. Status, Priority or Assignee.

To change the start and end date or the duration of a work package, click directly in the Gantt chart and change it via drag and drop.
All changes will also be tracked in the work packages [Activity](../../user-guide/activity).

![edit the projectplan](edit-projectplan.gif)

