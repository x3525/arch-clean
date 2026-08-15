// gcc -lX11 -o /usr/local/bin/XkbLayout

#include <stdio.h>
#include <X11/XKBlib.h>

int main(void) {
    Display *dpy = XOpenDisplay(NULL);

    if (!dpy) {
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

    XkbStateRec state;

    if (XkbGetState(dpy, XkbUseCoreKbd, &state) != Success) {
        XkbFreeKeyboard(xkb, 0, True);
        XCloseDisplay(dpy);
        return 1;
    }

    if (state.group > XkbMaxKbdGroup) {
        XkbFreeKeyboard(xkb, 0, True);
        XCloseDisplay(dpy);
        return 1;
    }

    Atom atom = xkb->names->groups[state.group];

    if (!atom) {
        XkbFreeKeyboard(xkb, 0, True);
        XCloseDisplay(dpy);
        return 1;
    }

    char *name = XGetAtomName(dpy, atom);

    if (!name) {
        XkbFreeKeyboard(xkb, 0, True);
        XCloseDisplay(dpy);
        return 1;
    }

    printf("%s\n", name);

    XFree(name);

    XkbFreeKeyboard(xkb, 0, True);
    XCloseDisplay(dpy);
}
