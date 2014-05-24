--[[

	LOVEFluid was created by Catlinman and can be forked on GitHub

	-> https://github.com/Catlinman/LOVE2D-FluidSystem

	This file contains the needed code to use and incorporate real time fluid dynamics for your 2D sidescroller. The
	system itself is still work in progress which means that improvements and additional functionality is still to come.

	Feel free to modify the file to your liking as long as I am credited for the original work. For more information please
	refer to the following link:

	-> https://github.com/Catlinman/LOVE2D-FluidSystem/blob/master/LICENSE.md
	
	I have attempted to comment most of the code to allow those not familiar with LOVE to jump faster into modifying the code.
	To remove all comments simply use a program like Sublime Text 2 and replace everything with whitespace using the following regex lines:

	--"[^\[\]"]*?$

	I have added quotation marks to the previous line to avoid the breaking of this comment block. You will need to remove those to parse the regex.

--]]

--[[
	These variables are local and only bound to the scope of this file.
	Use the fluid.get() function to return a reference to one of the currently loaded fluid systems.
-]]

local systems = {} -- Table containing the fluid systems
local id = 1 -- Fluid system reference identification

fluidsystem = {} -- Global variable containing the functions used to create and modify the fluid system

-- Calling this function instantiates a new fluid system
function fluidsystem.new()
	local system = {}

	-- This value defaults to 0.981 since the system is intended for sidescrolling games. A value of zero might be useful for top down based games.
	-- system.gravity = 0.981
	system.gravity = 0.05

	system.damping = 1 -- How much particles lose velocity when not colliding

	-- Assign the current system id and increment it
	system.id = id
	id = id + 1

	system.particles = {} -- Table containing the fluid particles
	system.particleId = 1 -- Each particle is given an id to track it in the particle table. This value increments as more particles are created.

	system.colliders = {} -- Table containing a set of objects that particles can collide with
	system.affectors = {} -- Table containing objects that affect the flow of particles

	system.collisionsNum = 1
	system.collisions = {}

	-- Add and remove particles using the following two methods
	function system:addParticle(x, y, vx, vy, color, r, mass)
		local particle = {} -- Create a new particle contained in a table

		-- Assign values that we will use to track certain states of the particle
		particle.x = x or 0
		particle.y = y or 0

		-- Velocity values
		particle.vx = vx or 0
		particle.vy = vy or 0

		-- Color, radius and collider
		particle.color = color or {255, 255, 255, 255} -- Colors: {RED, GREEN, BLUE, ALPHA/OPACITY}
		particle.r = r or 8
		particle.collider = fluidsystem.createCircleCollider(particle.r)

		-- Id assignment
		particle.id = self.particleId
		self.particleId = self.particleId + 1

		-- Add the particle to this system's particle table
		self.particles[particle.id] = particle

		return particle
	end

	function system:removeParticle(id)
		-- Lookup the particle by it's id in the particle table
		if self.particles[id] then
			self.particles[id] = nil -- Destory the particle reference
		end
	end

	-- Removes all particles from the fluid system
	function system:removeAllParticles()
		for i, particle in pairs(self.particles) do
			particle = nil
		end
	end

	-- Apply an impulse at the given coordinates using the following method
	function system:applyImpulse(x, y, strength)

	end

	-- Method to simulate a frame of the simulation. This is where the real deal takes place.
	function system:simulate(dt)
		for i, particle in pairs(self.particles) do
			-- Add the system's gravity to the particles velocity
			particle.vy = particle.vy + self.gravity

			-- We apply each particles velocity to it's current position
			particle.x = particle.x + particle.vx
			particle.y = particle.y + particle.vy

			-- Perform collision detection and resolution here
			for j, particle2 in pairs(self.particles) do
				-- Make sure we are not checking against an already checked particle
				if particle2 ~= particle then
					if fluidsystem.circleCollision(particle, particle2) then
						self.collisions[self.collisionsNum] = {particle, particle2}
					end
				end
			end

			-- Check if the particle is out of bounds and resolve the collision
			if particle.y + particle.r > 768 then
				particle.y = 768 - particle.r
				particle.vy = -(particle.vy / 2)
			elseif particle.y - particle.r < 0 then
				particle.y = 0 + particle.r
				particle.vy = -(particle.vy / 2)
			end

			if particle.x - particle.r < 0 then
				particle.x = 0 + particle.r
				particle.vx = -(particle.vx / 2)
			elseif particle.x + particle.r > 1024 then
				particle.x = 1024 - particle.r
				particle.vx = -(particle.vx / 2)
			end
		end

		for i, collision in pairs(self.collisions) do
			fluidsystem.circleResolution(collision[1], collision[2])
		end

		self.collisionsNum = 1
		self.collisions = {}
	end

	-- Method to draw the current state of the fluid simulation
	function system:draw()
		for i, particle in pairs(self.particles) do
			love.graphics.setColor(particle.color)
			love.graphics.circle("fill", particle.x, particle.y, particle.r)
		end

		love.graphics.setColor(255, 255, 255, 255) -- We reset the global color so we don't affect any other game drawing events
	end

	-- Add this new fluid system to the table of all currently instantiated systems
	systems[system.id] = system

	-- Return the system so the user has the option of saving a reference to it if necessary
	return system
end

-- Get a fluid system by it's id or name from the systems table
function fluidsystem.get(id)
	if systems[id] then
		return systems[id]
	end
end

-- Destroy an entire fluid system by it's id or name from the systems table
function fluidsystem.destroy()
	if systems[id] then
		systems[id].removeAllParticles()

		systems[id] = nil
	end
end

-- Fluid system collision handling
function fluidsystem.createBoxCollider(w, h)
	local collider = {}

	collider.collisionType = "box"
	collider.w = w or 16
	collider.h = h or 16

	return collider
end

function fluidsystem.createCircleCollider(r)
	local collider = {}

	collider.collisionType = "circle"
	collider.r = r or 8

	return collider
end

-- Image collider takes in an image to calculate pixel perfect collision
function fluidsystem.createPixelCollider(sx, sy, imagedata)
	local collider = {}

	collider.collisionType = "pixel"

	return collider
end

-- Basic box collision detection (c1/c2 arguments are the two colliders that should be checked for collision)
function fluidsystem.boxCollision(c1, c2)
	-- Convert this and the selected colliders types to those usable by box collision
	local c1w = c1.collider.w or c1.collider.r or 16
	local c1h = c1.collider.h or c1.collider.r or 16

	local c2w = c2.collider.w or c2.collider.r or 16
	local c2h = c2.collider.h or c2.collider.r or 16

	local c1x2, c1y2, c2x2, c2y2 = c1.x + c1w, c1.y + c1h, c2.x + c2w, c2.y + c2h

	-- Returns true if a box collision was detected
	if c1.x < c2x2 and c1x2 > c2.x and c1.y < c2y2 and c1y2 > c2.y then
		return {c1.x, c1x2, c1.y, c1y2, c2.y, c2x2, c2.y, c2y2}
	else
		return false
	end
end

-- Circle collision without the use of math.sqrt
function fluidsystem.circleCollision(c1, c2)
	local c1r = c1.collider.w or c1.collider.r or 8
	local c2r = c2.collider.w or c2.collider.r or 8

	local dist = (c2.x - c1.x)^2 + (c2.y - c1.y)^2

	-- Returns true if a circle collision was detected
	return (dist + (c2r^2 - c1r^2)) < (c1r*2)^2
end

function fluidsystem.pixelCollision(c1, c2)

end

-- Collision resolution functions
function fluidsystem.boxResolution(c1, c2)

end

function fluidsystem.circleResolution(c1, c2)
	local c1r = c1.collider.w or c1.collider.r or 8
	local c2r = c2.collider.w or c2.collider.r or 8

	local collisionPointX = ((c1.x * c2r) + (c2.x * c1r)) / (c1r + c2r)
	local collisionPointY = ((c1.y * c2r) + (c2.y * c1r)) / (c1r + c2r)

	c1.vx = (collisionPointX - c1.x) - (c1.vx / 2)
	c1.vy = (collisionPointY - c1.y) - (c1.vy / 2)
	c2.vx = (collisionPointX - c2.x) - (c2.vx / 2)
	c2.vy = (collisionPointY - c2.y) - (c2.vy / 2)

	c1.x = c1.x + c1.vx * 2
	c1.y = c1.y + c1.vy * 2
	c2.x = c2.x + c2.vx * 2
	c2.y = c2.y + c2.vy * 2

	print(c1.vx)
	print(c2.vx)
end

function fluidsystem.pixelResolution(c1, c2)

end