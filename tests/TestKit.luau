--!strict
-- A very small test helper so the project needs no extra packages.

local TestKit = {}

local results = { passed = 0, failed = 0, failures = {} :: { string } }

function TestKit.test(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if ok then
		results.passed += 1
	else
		results.failed += 1
		table.insert(results.failures, `{name}: {err}`)
	end
end

function TestKit.equal(actual: any, expected: any, label: string?)
	if actual ~= expected then
		error(`{label or "value"}: expected {tostring(expected)}, got {tostring(actual)}`, 2)
	end
end

function TestKit.near(actual: number, expected: number, label: string?)
	if math.abs(actual - expected) > 1e-6 then
		error(`{label or "value"}: expected {expected}, got {actual}`, 2)
	end
end

function TestKit.results()
	return results
end

return TestKit
