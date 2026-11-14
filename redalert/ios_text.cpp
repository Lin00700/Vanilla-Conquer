#include "ios_text.h"

#ifdef IOS_BUILD
#include "ios_text_data.inc"

char const* IOS_Chinese_String(int string)
{
    for (unsigned int i = 0; i < sizeof(ios_zh_lines) / sizeof(ios_zh_lines[0]); ++i) {
        if (ios_zh_lines[i].id == string) {
            return ios_zh_lines[i].text;
        }
    }
    return nullptr;
}
#else
char const* IOS_Chinese_String(int)
{
    return nullptr;
}
#endif
