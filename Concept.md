# Conceptal model for psano

any thing labeled with (adv) would be for a more advanced editor, the first target
should be to implment anything without the tag.

## Methods and ideas

### focus on panels

The idea of focus may be needed to implement a menu for things such as "save as" which
will required some form of addition input. This would mean that the input handelr would
pass key strokes to the required panel.

## Object overview

### ui form

The screen would be managed by a Textform in much the same way a gui app is contained
by a Form.

This form would contain information such as its position in the buffer, and a list
of panels that it contains. For the first version it would be simpler to just have
all panels stacked verticaly. Nano has little in the way of right left layout.

This form would also be responsible for calling any draw functions that are needed.

### draw area object

This would basicaly be a proxy for the console, so that panels can give draw calls
in the contex of thier own panel but for the items to be drawn on to the correct
place in the console buffer. Would also act as a "secure" draw area that would prevent
panels drawing over other panels. This would be anolugus to graphics objects in GUIs.

### ui panels

These would be contained by the screen and would implement draw calls. They may also
register (global) shortcuts with the input handler. In theory they should be able to contain
other panels, but this might not be needed.

### input handler

Ths input handler would be the "default" state of the ui. It would listen to any key
input by the user and either call global shortcuts or pass the input chars to the
currently focused panel.

### editor panel

this would extend the panel class and managed the translation between a internal buffer (list of char[]s?)

It will need to convert each line of the buffer to a displayed version, ie converting
tabs to 4 spaces and to limit the visible line length.

It will also need to handle key events for both text input, and for moving the cursor around
the buffer and screen. (this should probably be put in its own class.)

### menu panel

This would impliment a list of actions. Sort the list and compose a horizontal layout of the
avalitable actions. The actions would need to register global keys and handle any key events
for them.

### actions

Some actions that would need to be implimented

* Exit
* Save
* open (maybe not/adv)
* Cut (adv)
* Paste (adv)
* Exit with save prompt (adv)

### status/input panel (adv)

A single or 2 line panel that would display any feedback messages, such as save successful and act as
an input to questions such as do you want to save before exiting? or what do you want to save as