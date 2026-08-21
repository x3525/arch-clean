#include <stdio.h>
#include <X11/XKBlib.h>

int main(void) {
    Display *display = XOpenDisplay(NULL);

    if (!display) {
        return 1;
    }

    XkbStateRec state;

    if (XkbGetState(display, XkbUseCoreKbd, &state) != Success) {
        XCloseDisplay(display);
        return 1;
    }

    if (state.group >= XkbNumKbdGroups) {
        XCloseDisplay(display);
        return 1;
    }

    XkbDescPtr xkb = XkbGetMap(display, 0, XkbUseCoreKbd);

    if (!xkb) {
        XCloseDisplay(display);
        return 1;
    }

    if (XkbGetNames(display, XkbGroupNamesMask, xkb) != Success) {
        XkbFreeKeyboard(xkb, 0, True);
        XCloseDisplay(display);
        return 1;
    }

    if (!xkb->names) {
        XkbFreeKeyboard(xkb, 0, True);
        XCloseDisplay(display);
        return 1;
    }

    unsigned int num_groups = 0;

    for (unsigned int i = 0; i < XkbNumKbdGroups; i++) {
        if (xkb->names->groups[i] != None) {
            num_groups++;
        }
    }

    if (num_groups == 1) {
        XkbFreeKeyboard(xkb, 0, True);
        XCloseDisplay(display);
        return 0;
    }

    Atom atom = xkb->names->groups[state.group];

    if (!atom) {
        XkbFreeKeyboard(xkb, 0, True);
        XCloseDisplay(display);
        return 1;
    }

    int status = 0;

    char *name = XGetAtomName(display, atom);

    if (!name) {
        status = 1;
    } else {
        if (printf("%s\n", name) < 0) {
            status = 1;
        }
        XFree(name);
    }

    XkbFreeKeyboard(xkb, 0, True);
    XCloseDisplay(display);

    return status;
}
