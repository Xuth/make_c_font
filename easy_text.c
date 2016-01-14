/*
  easy_text.c
  Copyright 2009-2010 by Jim Leonard (jim@xuth.net)
*/


#include "easy_text.h"
#include <stdlib.h>
#include <stdio.h>

typedef struct {
	int width;
	unsigned char *data;
} schar;

/* verify that a character is within the valid range for a font.  If not use '?' */
#define CHAR_TEST_LOW(ch, font) (font->min_c > (ch) ? '?' : (ch))
#define CHAR_TEST_HIGH_LOW(ch, font) (font->max_c < (ch) ? '?' : CHAR_TEST_LOW(ch,font))

/* get the array element in the variable named "font" that has the desired character
   this calls the above test macros to coerce the character to a valid one.
*/
#define SC(ch) (font->c[CHAR_TEST_HIGH_LOW(ch, font) - font->min_c])

/* given a null terminated string of text and a font, calculate the width and height
   needed to render that string.
*/
int et_CalcRectangle(char *text, simple_font_t *font, int *width, int *height) {
	*height = font->height;
	*width = 0;
	
	int i;
	for (i = 0; text[i]; ++i)
		*width += SC(text[i]).width;
	*width += (i - 1) * font->between_width;
	return 1;	
}

/* allocate a simple buffer of width and height (probably calculated by et_CalcRectangle()
   above.
*/
rgb_buffer_t *et_AllocateRgbBuffer(int width, int height) {
	rgb_buffer_t *buf;
	if (NULL == (buf = (rgb_buffer_t *)malloc(sizeof(rgb_buffer_t) + width * height * 3))) {
		fprintf(stderr, "Can't allocate rgb buffer!");
		return NULL;
	}
	buf->width = width;
	buf->height = height;
	buf->rgb = ((void *)buf) + sizeof(rgb_buffer_t);
	return buf;
}

/* properly dispose of a buffer created by et_AllocateRgbBuffer() */
void et_FreeRgbBuffer(rgb_buffer_t *buf) {
	free(buf);
}

/* fill the buffer with a given color */
void et_FillBuffer(rgb_buffer_t *buf, color_t col) {
	unsigned char *b = buf->rgb;
	
	int i;
	for (i = 0; i < buf->width * buf->height; ++i) {
		*(b++) = col.rgb[0];
		*(b++) = col.rgb[1];
		*(b++) = col.rgb[2];
	}
}

/* i:  intensity
   fg: foreground
   bg: background
   there is no error checking
*/
static inline int CalcSubPixel(int i, int fg, int bg) {
	return (fg - bg) * i / 255 + bg;
}

static void RenderChar(char ch, simple_font_t *font, color_t col, rgb_buffer_t *buf, int ix, int iy) {
	int x, y, c;
	for (y = 0; y < font->height; ++y) {
		if (y + iy < 0)
			continue;
		if (y + iy >= buf->height)
			continue;
		
		unsigned char *buf_ptr = &buf->rgb[((y+iy) * buf->width + ix) * 3];
		unsigned char *font_ptr = &SC(ch).data[y * SC(ch).width];
		
		for (x = 0; x < SC(ch).width; ++x, buf_ptr += 3, ++font_ptr) {
			if (x + ix < 0)
				continue;
			if (x + ix >= buf->width)
				continue;
			
			/* most chars have a bunch of empty space... do less work */
			if (!*font_ptr)
				continue;
			
			for (c = 0; c < 3; ++c) {
				buf_ptr[c] = CalcSubPixel(*font_ptr, col.rgb[c], buf_ptr[c]);
			}
		}
	}
}

/* Render a string at a specific location of an rgb buffer */
void et_RenderText(char *text, simple_font_t *font, color_t col, rgb_buffer_t *buf, int x, int y) {
	while(*text) {
		RenderChar(*text, font, col, buf, x, y);
		x += SC(*text).width + font->between_width;
		text++;
	}
}
