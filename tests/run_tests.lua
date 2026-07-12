-- Central Test Runner
local helper = require("tests.test_helper")

print("=======================================")
print("Running F3K Training Full Test Suite...")
print("=======================================")

-- Load all task tests
dofile("tests/test_task_a.lua")
dofile("tests/test_task_b.lua")
dofile("tests/test_task_c.lua")
dofile("tests/test_task_d.lua")
dofile("tests/test_task_d2.lua")
dofile("tests/test_task_f.lua")
dofile("tests/test_task_ff.lua")
dofile("tests/test_task_g.lua")
dofile("tests/test_task_h.lua")
dofile("tests/test_task_i.lua")
dofile("tests/test_task_j.lua")
dofile("tests/test_task_k.lua")
dofile("tests/test_task_l.lua")
dofile("tests/test_task_m.lua")
dofile("tests/test_task_n.lua")
dofile("tests/test_task_qt.lua")

print("=======================================")
print(string.format("Test Results: %d passed, %d failed", helper.passed, helper.failed))
print("=======================================")

if helper.failed > 0 then
  os.exit(1)
else
  print("✅ All tests passed successfully!")
end
