#include <stdio.h>
#include <X11/XKBlib.h>

int main(void) {
    Display *dpy = XOpenDisplay(NULL);

    if (!dpy) {
        return 1;
    }

    XkbStateRec state;

    if (XkbGetState(dpy, XkbUseCoreKbd, &state) != Success) {
        XCloseDisplay(dpy);
        return 1;
    }

    if (state.group >= XkbNumKbdGroups) {
        XCloseDisplay(dpy);
        return 1;
    }

    XkbDescPtr xkb = XkbGetMap(dpy, 0, XkbUseCoreKbd);

    if (!xkb) {
        XCloseDisplay(dpy);
        return 1;
    }

    if (XkbGetNames(dpy, XkbGroupNamesMask, xkb) != Success) {
        XkbFreeKeyboard(xkb, 0, True);
        XCloseDisplay(dpy);
        return 1;
    }

    if (!xkb->names) {
        XkbFreeKeyboard(xkb, 0, True);
        XCloseDisplay(dpy);
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
        XCloseDisplay(dpy);
        return 0;
    }

    Atom atom = xkb->names->groups[state.group];

    if (!atom) {
        XkbFreeKeyboard(xkb, 0, True);
        XCloseDisplay(dpy);
        return 1;
    }

    int status = 0;

    char *name = XGetAtomName(dpy, atom);

    if (!name) {
        status = 1;
    } else {
        if (printf("%s\n", name) < 0) {
            status = 1;
        }
        XFree(name);
    }

    XkbFreeKeyboard(xkb, 0, True);
    XCloseDisplay(dpy);

    return status;
}
