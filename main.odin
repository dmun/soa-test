package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

GRAVITY :: [2]f32{0, 9.82}
DAMPENING_FACTOR :: 0.8

Particle :: struct {
	position: [2]f32,
	force:    [2]f32,
	velocity: [2]f32,
	mass:     f32,
	radius:   f32,
	color:    rl.Color,
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
			v := rl.Vector2{10, -5}
			r := f32(rl.GetRandomValue(5, 10))
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
			time := rl.GetFrameTime() * 5
			p.force += p.mass * GRAVITY
			p.velocity += p.force / p.mass * time
			p.position += p.velocity * time
			p.force = (0)

			// for _ in 0 ..< 8 {
			for &c in particles {
				if p == c {continue}

				angle := p.position - c.position
				len := math.abs(rl.Vector2Length(angle))
				angle = rl.Vector2Normalize(angle)
				if len <= p.radius + c.radius {
					p.velocity += angle * (len / p.radius + c.radius) * 0.05
					c.velocity -= angle * (len / p.radius + c.radius) * 0.05
					p.position += angle * (p.radius + c.radius - len) / 2
					c.position -= angle * (p.radius + c.radius - len) / 2
				}
			}
			// }

			height := f32(rl.GetScreenHeight())
			width := f32(rl.GetScreenWidth())
			if p.position.y > height - p.radius {
				p.velocity.y *= -1 * DAMPENING_FACTOR
				p.position.y = height - p.radius
			}

			if p.position.x > width - p.radius {
				p.velocity.x *= -1 * DAMPENING_FACTOR
				p.position.x = width - p.radius
			}

			if p.position.x < p.radius {
				p.velocity.x *= -1 * DAMPENING_FACTOR
				p.position.x = p.radius
			}
		}

		// draw
		for &p in particles {
			c := math.clamp(rl.Vector2Length(p.velocity), 0, 100)
			rl.DrawCircleV(p.position, p.radius, rl.ColorFromHSV(100 - c, 1, 1))
			// rl.DrawRectangleV(p.position, p.radius, rl.BLUE)
		}
	}
}
