package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

GRAVITY :: [2]f32{0, 9.82}
DAMPENING_FACTOR :: 0.3

Particle :: struct {
	position: [2]f32,
	force:    [2]f32,
	velocity: [2]f32,
	mass:     f32,
	radius:   f32,
	color:    rl.Color,
}

calc_vel :: proc(p: ^Particle, c: ^Particle, cr: f32) -> [2]f32 {
	ratio := (cr + 1) * c.mass / (p.mass + c.mass)
	v_diff := p.velocity - c.velocity
	p_diff := p.position - c.position
	proj := linalg.projection(v_diff, p_diff)

	return p.velocity - proj * ratio
}

main :: proc() {
	rl.SetConfigFlags({.MSAA_4X_HINT})
	rl.SetGesturesEnabled({.DRAG})
	rl.InitWindow(800, 600, "soa")
	rl.SetTargetFPS(240)

	particles: [dynamic]Particle

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.ClearBackground(rl.BLACK)
		rl.DrawFPS(0, 0)
		rl.DrawText(rl.TextFormat("n=%d", len(particles)), 0, 18, 18, rl.WHITE)

		// input
		if rl.IsMouseButtonDown(.LEFT) {
			r := f32(rl.GetRandomValue(10, 10))
			p := Particle {
				rl.GetMousePosition(),
				(0),
				(0),
				r,
				r,
				rl.ColorFromHSV(f32(rl.GetRandomValue(0, 255)), 0.5, 0.8),
			}
			append(&particles, p)
		}

		// update
		for &p in particles {
			time := rl.GetFrameTime() * 4

			p.force += p.mass * GRAVITY
			p.velocity += p.force / p.mass * time
			p.position += p.velocity * time
			p.force = (0)

			// for _ in 0 ..< 8 {
			for &c in particles {
				if p == c {continue}
                if linalg.distance(p.position, c.position) > p.radius * 3 {
                    continue
                }

				angle := p.position - c.position
				len := math.abs(rl.Vector2Length(angle))
				angle = rl.Vector2Normalize(angle)
				if len <= p.radius + c.radius {
					cr := f32(0.8)
					p1 := calc_vel(&p, &c, cr)
					c1 := calc_vel(&c, &p, cr)

                    // p1 = p1 if linalg.length(p1) > 1 else p1 * 0.1
                    // c1 = c1 if linalg.length(c1) > 1 else c1 * 0.1

                    p.velocity = p1
                    c.velocity = c1
					// p.velocity += angle * (len / p.radius + c.radius) / p.mass * time * 30
					// c.velocity -= angle * (len / p.radius + c.radius) / c.mass * time * 30
					p.position += angle * (p.radius + c.radius - len) / 2
					c.position -= angle * (p.radius + c.radius - len) / 2
				}
			}
			// }


			height := f32(rl.GetScreenHeight())
			width := f32(rl.GetScreenWidth())
			if p.position.y > height - p.radius {
				p.velocity.y *= -1 * DAMPENING_FACTOR
                p.velocity.x *= 0.5
				p.position.y = height - p.radius
			}

			if p.position.x > width - p.radius {
				// p.position.x = p.radius
				// p.position.y = 0
				p.velocity.x *= -1 * DAMPENING_FACTOR
				p.position.x = width - p.radius
			}

			if p.position.x < p.radius {
				// p.position.x = width - p.radius
				// p.position.y = 0
				p.velocity.x *= -1 * DAMPENING_FACTOR
				p.position.x = p.radius
			}
		}

		// draw
		for &p in particles {
			c := math.clamp(rl.Vector2Length(p.velocity), 0, 100)
            color := rl.ColorFromHSV(100 - c, 1, 1)
			rl.DrawCircleV(p.position, p.radius, color)
			// rl.DrawRectangleV(p.position, p.radius, rl.BLUE)
		}
	}
}
