/* winsize.odin - terminal size handling
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
import "core:sys/linux"

@(private="file")
TIOCGWINSZ :: 0x5413

@(private="file")
prev_action: linux.Sig_Action(any)

WinSize :: struct {
	y: u16,
	x: u16,
	xpixel: u16,
	ypixel: u16
}

win_update: bool
win_size: WinSize

win_getsize :: proc "c" () {
	linux.syscall(linux.SYS_ioctl, 0, TIOCGWINSZ, &win_size)
}

in_bounds :: proc(x: i32, y: i32) -> bool {
	return x >= 0 && y >= 0 && x < i32(win_size.x) && y < i32(win_size.y*2)
}

@(private="file")
signal_winch :: proc "c" (sig: linux.Signal) {
	win_update = true
	win_getsize()
}

win_sigaction :: proc "c" () {
	sa_winch := linux.Sig_Action(any) {
		handler = signal_winch,
		flags = nil,
		restorer = nil,
		mask = 0
	}
	linux.rt_sigaction(.SIGWINCH, &sa_winch, &prev_action)
}

win_unsigaction :: proc "c" () {
	linux.rt_sigaction(.SIGWINCH, &prev_action, cast(^linux.Sig_Action) nil)
}
