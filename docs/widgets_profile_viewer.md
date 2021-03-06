---
title: Widgets - Profile viewer
---

{% include xstyle.css %}

### Profile viewer

#### Description

The _profile viewer_ widget displays the results stored in the _trace.log_ file that a software compiled with DMD outputs when it's compiled with the `-profile` switch.

![](img/profile_viewer.png)

The pie displays the weight of a each function for a particular criterion.
This criterion can be selected in the combo box that's located in the toolbar.

The list displays all the results, which can be inspected more accurately after sorting a column.

#### Toolbar

- <img src="{%include icurl%}folder/folder.png" class="tlbric"/>: Propose to open the _trace.log_ from a dialog.
- <img src="{%include icurl%}arrow/arrow_update.png" class="tlbric"/>: Reloads the current _trace.log_ or tries to load it from the current directory.
