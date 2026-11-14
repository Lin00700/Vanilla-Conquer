#pragma once

// 8x8 UI font for the iOS Chinese string table. Null on desktop builds.
const void* IOS_CJK_Font(void);

// Pixel width of one slot in that font, not including FontXSpacing.
// Zero when the slot is empty.
int IOS_CJK_Glyph_Width(unsigned char glyph);
