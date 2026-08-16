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

    if (state.group > XkbMaxKbdGroup) {
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

    Atom atom = xkb->names->groups[state.group];

    if (!atom) {
        XkbFreeKeyboard(xkb, 0, True);
        XCloseDisplay(display);
        return 1;
    }

    char *name = XGetAtomName(display, atom);

    if (!name) {
        XkbFreeKeyboard(xkb, 0, True);
        XCloseDisplay(display);
        return 1;
    }

    printf("%s\n", name);

    XFree(name);
    XkbFreeKeyboard(xkb, 0, True);
    XCloseDisplay(display);
}
