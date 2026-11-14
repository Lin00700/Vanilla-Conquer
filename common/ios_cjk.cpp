#include "ios_cjk.h"

#ifdef IOS_BUILD
#include "ios_cjk_data.inc"

const void* IOS_CJK_Font(void)
{
    return ios_cjk_font;
}

int IOS_CJK_Glyph_Width(unsigned char glyph)
{
    return ios_cjk_width[glyph];
}
#else
const void* IOS_CJK_Font(void)
{
    return nullptr;
}

int IOS_CJK_Glyph_Width(unsigned char)
{
    return 0;
}
#endif
