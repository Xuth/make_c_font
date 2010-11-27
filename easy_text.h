#ifndef EASY_TEXT_H_
#define EASY_TEXT_H_
/*
  easy_text.h
  Copyright 2009 - 2010 by Jim Leonard (jim@xuth.net)
*/

typedef struct {
    int min_c;  /* ascii code of first char */
    int max_c;  /* ascii code of last char */
    int height;  /* height of the font */
    int between_width;  /* width of space between characters */
    struct {
        int width;  /* width of the character */
        unsigned char *data; /* one byte per pixel, width first */
    } c[0];
} simple_font_t;

// define color_t as an array of 3 unsigned chars
typedef struct {
	unsigned char rgb[3];
} color_t;

// poor mans constructor for color
static inline color_t et_col(int r, int g, int b) {
	color_t c = {{r,g,b}};
	return c;
}

typedef struct {
	int width;
	int height;
	unsigned char *rgb;
} rgb_buffer_t;

static inline rgb_buffer_t et_buffer(int width, int height, unsigned char *rgb) {
	rgb_buffer_t buf = {width, height, rgb };
	return buf;
}

int et_CalcRectangle(char *text, simple_font_t *font, int *width, int *height);
rgb_buffer_t *et_AllocateRgbBuffer(int width, int height);
void et_FreeRgbBuffer(rgb_buffer_t *buf);
int et_FillBuffer(rgb_buffer_t *buf, color_t col);
int et_RenderText(char *text, simple_font_t *font, color_t col, rgb_buffer_t *buf, int x, int y);

#endif /*EASY_TEXT_H_*/
