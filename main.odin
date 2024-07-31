/* main.odin - terminal graphics circle demo
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
import "core:time"
import "core:fmt"
import "core:mem"

BufType :: [dynamic]Pixel

buffer: BufType
should_exit: bool

bufsize :: proc() -> u32 {
	return u32(win_size.x * win_size.y * 2)
}

signal_term :: proc "c" (sig: linux.Signal) {
	should_exit = true
}

main :: proc() {
	should_exit = false
	sa_term := linux.Sig_Action(any) {
		handler = signal_term,
		flags = { .RESETHAND },
		restorer = nil,
		mask = 0
	}
	win_getsize()
	win_sigaction()
	buffer = make(BufType, bufsize())
	defer {
		delete(buffer)
		win_unsigaction()
	}
	linux.rt_sigaction(.SIGINT, &sa_term, cast(^linux.Sig_Action) nil)
	linux.rt_sigaction(.SIGTERM, &sa_term, cast(^linux.Sig_Action) nil)
	for !should_exit {
		if win_update {
			win_update = false
			resize(&buffer, bufsize())
		}
		circle(10, 10, 10, Pixel { 255, 0, 0, 255 })
		circle(20, 30, 7, Pixel { 0, 0, 255, 255 })
		circle(60, 40, 20, Pixel { 0, 255, 0, 255 })
		circle(70, 45, 8, Pixel { 255, 0, 255, 255 })
		render()
		mem.zero(raw_data(buffer), int(bufsize() * size_of(Pixel)))
		time.sleep(50 * time.Millisecond)
	}
	tput_sgr0()
	fmt.println("\nTerminated")
}
