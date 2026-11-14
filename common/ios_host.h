// iOS host helpers for the Red Alert client. The .mm implementation is only
// compiled into the iOS app. Desktop builds include this header for the
// inline layout helpers, which compile down to nothing.
#pragma once

#ifdef IOS_BUILD

#ifdef __cplusplus
extern "C" {
#endif

// Sandbox Documents directory. Also the process working directory.
const char* IOS_Documents_Directory(void);

// Blocks on a Chinese full-screen message until REDALERT.MIX and MAIN.MIX
// are in Documents (or a subfolder). Does not return if they are missing.
void IOS_Wait_For_Game_Data(void);

// Landscape size of the phone, in points. The game buffer itself is the
// classic 320x200 or 640x400 picture; SDL stretches that to this panel.
void IOS_Choose_Resolution(int* width, int* height);

// Notch / Dynamic Island inset, in game pixels (points), used to keep the
// sidebar off the island. The map itself is not inset.
int IOS_Safe_Right_Pixels(void);

// Home-indicator inset, in game pixels. Reported for touch layout; the
// framebuffer is not letterboxed by it.
int IOS_Safe_Bottom_Pixels(void);

// Full-screen Chinese message. Does not return: a silent exit was hiding
// startup failures after the MIX files were found.
void IOS_Show_Fatal(const char* message);

#ifdef __cplusplus
}
#endif

#endif

#ifdef __cplusplus

// Notch inset in game pixels. The framebuffer is 320 or 640 wide and then
// stretched to the phone, so a 47-point island is only a few game pixels.
inline int IOS_Safe_Right_Game()
{
#ifdef IOS_BUILD
    extern int ScreenWidth;
    int panel_w = 0;
    int panel_h = 0;
    IOS_Choose_Resolution(&panel_w, &panel_h);
    int safe = IOS_Safe_Right_Pixels();
    if (panel_w > 0 && ScreenWidth > 0 && ScreenWidth < panel_w) {
        safe = (safe * ScreenWidth + panel_w / 2) / panel_w;
    }
    return safe;
#else
    return 0;
#endif
}

// Moves the classic 640-wide right-hand chrome (sidebar, power bar, tabs)
// onto the right edge, inside the notch inset. Negative on a phone that is
// narrower than 640 points, which keeps the sidebar on screen.
inline int IOS_Chrome_Shift()
{
#ifdef IOS_BUILD
    extern int ScreenWidth;
    extern int RESFACTOR;
    return (ScreenWidth - IOS_Safe_Right_Game()) - (320 * RESFACTOR);
#else
    return 0;
#endif
}

// Horizontal nudge that recenters a control authored against a 640-wide screen.
inline int IOS_Menu_Shift()
{
#ifdef IOS_BUILD
    extern int ScreenWidth;
    extern int RESFACTOR;
    return (ScreenWidth - (320 * RESFACTOR)) / 2;
#else
    return 0;
#endif
}

#endif
