/* draw.odin - drawing functions
 * Copyright (C) 2024  Marisa <private>
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 * 
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

package circle
import "core:math"
import "core:fmt"

Pixel :: [4]u8
null_pixel :: Pixel { 0, 0, 0, 0 }

@(private="file")
tput_home :: proc() {
	fmt.print("\e[H", flush = false)
}

tput_sgr0 :: proc() {
	fmt.print("\e[m", flush = false)
}

@(private="file")
tput_sgr_bg0 :: proc() {
	fmt.print("\e[49m", flush = false)
}

@(private="file")
tput_sgr_rgb :: proc(p: ^Pixel, bg: bool) {
	fmt.printf("\e[%c8;2;%d;%d;%dm", u8(bg) + '3', p^.r, p^.g, p^.b, flush = false)
}

render :: proc() {
	x, y: i32
	pixpair: [2]Pixel
	pixpair_set: [2]bool
	cur_color_hi, cur_color_lo: u32
	prev_color: [2]u32 // fg, bg
	tput_home()
	for y = 0; y < i32(win_size.y*2); y += 2 {
		for x = 0; x < i32(win_size.x); x += 1 {
			pixpair[0] = get_pixel(x, y)
			pixpair[1] = get_pixel(x, y+1)
			pixpair_set[0] = pixpair[0].a == 255
			pixpair_set[1] = pixpair[1].a == 255
			if pixpair_set[0] && !pixpair_set[1] { // top pixel set
				cur_color_hi = rgb_to_u32(pixpair[0])
				if prev_color[1] != 0 {
					prev_color[1] = 0
					tput_sgr_bg0()
				}
				if prev_color[0] != cur_color_hi {
					prev_color[0] = cur_color_hi
					tput_sgr_rgb(&pixpair[0], false)
				}
				fmt.print("\u2580", flush = false) // upper half block
			} else if !pixpair_set[0] && pixpair_set[1] { // bottom pixel set
				cur_color_lo = rgb_to_u32(pixpair[1])
				if prev_color[1] != 0 {
					prev_color[1] = 0
					tput_sgr_bg0()
				}
				if prev_color[0] != cur_color_lo {
					prev_color[0] = cur_color_lo
					tput_sgr_rgb(&pixpair[1], false)
				}
				fmt.print("\u2584", flush = false) // lower half block
			} else if pixpair_set[0] && pixpair_set[1] {
				cur_color_hi = rgb_to_u32(pixpair[0])
				cur_color_lo = rgb_to_u32(pixpair[1])
				if cur_color_hi == cur_color_lo {
					if prev_color[0] != cur_color_hi {
						prev_color[0] = cur_color_hi
						tput_sgr_rgb(&pixpair[0], false)
					}
					fmt.print("\u2588", flush = false) // full block
					continue
				}
				// print half block with fg and bg.
				// upper half of block is fg, lower is bg
				if prev_color[1] != cur_color_lo {
					prev_color[1] = cur_color_lo
					tput_sgr_rgb(&pixpair[1], true)
				}
				if prev_color[0] != cur_color_hi {
					prev_color[0] = cur_color_hi
					tput_sgr_rgb(&pixpair[0], false)
				}
				fmt.print("\u2580", flush = false)
			} else {
				if prev_color[1] != 0 {
					prev_color[1] = 0
					tput_sgr_bg0()
				}
				fmt.print(" ", flush = false)
			}
		}
	}
}

rgb_to_u32 :: proc(p: Pixel) -> u32 {
	return (u32(p.r) << 24) | (u32(p.g) << 16) | (u32(p.b) << 8)
}

set_pixel :: proc(x: i32, y: i32, p: Pixel) {
	if !in_bounds(x, y) { return }
	buffer[y * i32(win_size.x) + x] = p
}

clear_pixel :: proc(x: i32, y: i32) {
	if !in_bounds(x, y) { return }
	buffer[y * i32(win_size.x) + x] = null_pixel
}

get_pixel :: proc(x: i32, y: i32) -> Pixel {
	if !in_bounds(x, y) { return null_pixel }
	return buffer[y * i32(win_size.x) + x]
}

@(private="file")
in_radius :: proc(x: f32, y: f32, radius: f32) -> bool {
	return math.hypot(abs(x-radius), abs(y-radius)) <= radius
}

circle :: proc(x: i32, y: i32, radius: i32, color: Pixel) {
	size: i32 = radius*2 + (1-radius%2)
	for i: i32 = 0; i < size; i += 1 {
		for j: i32 = 0; j < size; j += 1 {
			if in_radius(f32(j), f32(i), f32(radius)) {
				set_pixel(x - radius + j, y - radius + i, color)
			}
		}
	}
}
