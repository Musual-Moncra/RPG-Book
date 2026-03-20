export type Mob = {
	Instance: Model,
	Config: any,
	Root: BasePart,
	Enemy: Humanoid,
	Origin: CFrame,
	Respawn: (Mob) -> ()
}

return {}