# HabitMaker
HabitMaker is a productivity application that allows the user to create weekly or daily repeating tasks that they can check off.

##### Features by View:
  - Login View
    - UUID and Api Key fields.
    - Continue button to take you to the task tab view.
    - Info button - Habitica doesn't have a login function in their API but they do require a UUID and an Api Key to get, create, update, and delete user tasks. The Info button shows you where to find those (you must be logged into the site for the 'find UUID' function to take you to the proper settings url).
    - Sign in button if you don't already have an account.
  - Task Tab View
    - There are two tabs that contain table views. The Weekly Task tab, and the Daily Task tab.
    - You can add or refresh the current type of table from here, or just logout to go back to the login view.
  - Weekly Task Table
    - Weekly tasks allow you to create tasks that can be checked off 1 or more times per week. The goal is to complete the task by Sunday because when Monday begins the checkbox and repetition counters are reset.
    - Each Task has a checkbox, a title, a repetitions counter (shows you how many repeats you've completed against how many total repeats you've set for the task - doesn't show up if less than 2 repeats), an edit button, and a delete button.
  - Daily Task Table
    - Just like the weekly tasks except these tasks will reset every day.
  - Add task / Edit task View
    - This view pops up if you click the '+' button in a table view or if you click the edit button in an existing task.
    - The task cannot be saved unless you've at least given it a title.
    - You can also increment or decrement a counter to set how many times you want to repeat a task that day or week. Note: If you haven't reached the maximum when you check off a task (in the table view), it will increment the repetitions completed counter and uncheck the task.
    - You can set a priority for the Task, the tasks will be sorted from highest to lowest and the background color of the task will change based on this setting.
    - You can also give the task a note (which can quickly be seen if you select the task in the table view)


##### Why I used Habitica for the API...
I used the [Habitica] API to store the tasks because it's a fantastic productivity gamification app with tons of features I really like. One feature I especially find really useful is what they call "dailies". These are tasks that can be set to repeat on any day of the week. If all weekdays are selected, it's a true daily task, but you can just set a couple of days and then it's more of a weekly task that you do on specific days. You can also add a checklist to the task so that the main task is really only complete if each item on the checklist is checked off. I love this functionality and haven't seen it that much in other apps, so Habitica provides the perfect base for me to extend this functionality and tailor it to my preferences.

##### How I Wanted to Extend the Functionality of the Habitica API...
There is something I find frustrating about Habitica's dailies and that's that you have to complete the task on the specific day of the week that you have selected. So if I want to do a weekly task and have it reset every Monday, I have to set the day for the task to Sunday and make sure to check it off on Sunday. Most of the time I find myself wanting to make sure I do the task *within* the week or a specific number of times randomly throughout the week. For Example: going for a run -- perhaps I'd like to do that 3 times a week but don't care which days I specifically do it on. There is a way to finegle the Habitica UI to do it this way; basically you make an item in the checklist represent one repetition of the task, then check the main task on the day it's due if all the checklist items are completed. Setting it up this way makes the UI kind of clunky though.

##### My Solution...
So what my app does is automatically create a Habitica task so it works in the way I would finegle it to work on Habitica -- give it a checklist item for each time I'd like to repeat the task, make it daily or weekly, and weekly tasks notify Habitica on Sunday to check off the main task if all checklist Items are completed. So in the UI of my app, all you have to see is the checkbox, task name, and repetition counter.

[//]: # (reference links below...)
   [habitica]: <https://habitica.com>

