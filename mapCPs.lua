-- A table of maps and their checkpoints, gets read in by carBrain 
--mapCPs.lua
print("loading maps")
LegacyAxolotSpeedway= {
            {['id'] = 1, ['x1'] = 122.375, ['y1'] = 64.500,  ['x2']=  69.625,  ['y2'] = 65.775,  ['action'] = 0, ['dir'] = 0, ['nxt'] = 2},
            {['id'] = 2, ['x1'] = 122.375, ['y1'] = 191.375, ['x2'] = 69.625,  ['y2'] = 193.375, ['action'] = 1, ['dir'] = 1, ['nxt'] = 3},
            {['id'] = 3, ['x1'] = 190.375, ['y1'] = 197.375, ['x2'] = 192.625, ['y2'] = 250.375, ['action'] = 1, ['dir'] = 2, ['nxt'] = 4},
            {['id'] = 4, ['x1'] = 197.625, ['y1'] = 58.875,  ['x2'] = 250.375, ['y2'] = 60.625,  ['action'] = 1, ['dir'] = 3, ['nxt'] = 5},
            {['id'] = 5, ['x1'] = 194.325, ['y1'] = 58.625,  ['x2'] = 193.000, ['y2'] = 5.325,   ['action'] = -1,['dir'] = 2, ['nxt'] = 6},
            {['id'] = 6, ['x1'] = 133.625, ['y1'] = -4.875,   ['x2'] = 186.375, ['y2'] = -3.000,   ['action'] = -1,['dir'] = 1, ['nxt'] = 7},
            {['id'] = 7, ['x1'] = 255.375, ['y1'] = -58.375, ['x2'] = 256.125, ['y2'] = -5.625,  ['action'] = 1, ['dir'] = 2, ['nxt'] = 8},
            {['id'] = 8, ['x1'] = 261.625, ['y1'] = -61.125, ['x2'] = 314.375, ['y2'] = -63.625, ['action'] = 1, ['dir'] = 3, ['nxt'] = 9},
            {['id'] = 9, ['x1'] = 125.875, ['y1'] = -69.125, ['x2'] = 124.375, ['y2'] = -122.375,['action'] = 1, ['dir'] = 0, ['nxt'] = 1}
            }
axolotSpeedCams= {
                {['id'] = 1, ['x'] = 124.796, ['y'] = 64.8315,  ['z']= 11.2, ['angle'] = 2.5, ['zoom'] = 60},
                {['id'] = 2, ['x'] = 251.048, ['y'] = 204.456,  ['z']=  14.2, ['angle'] = 1.5, ['zoom'] = 60},
                {['id'] = 3, ['x'] = 185.785, ['y'] = -0.35637,  ['z']=  5.20, ['angle'] = -0.4, ['zoom'] = 60},
                {['id'] = 4, ['x'] = 321.711, ['y'] = -60,0708,  ['z']=  31.955, ['angle'] = 1.3, ['zoom'] = 60},
                }
saltyCircut = {
                {['id'] = 1, ['x1'] = -133.625, ['y1'] = 0.625, ['x2'] = -186.375, ['y2'] = 1.375, ['action'] = 0, ['nxt'] = 2},
                {['id'] = 2, ['x1'] = -133.625, ['y1'] = 251.625, ['x2'] = -186.375, ['y2'] = 258.625, ['action'] = 1, ['nxt'] = 3},
                {['id'] = 3, ['x1'] = -6.875, ['y1'] = 261.625, ['x2'] = -0.375, ['y2'] = 314.375, ['action'] = -1, ['nxt'] = 4},
                {['id'] = 4, ['x1'] = 5.625, ['y1'] = 377.625, ['x2'] = 58.375, ['y2'] = 386.625, ['action'] = -1, ['nxt'] = 5},
                {['id'] = 5, ['x1'] = -186.125, ['y1'] = 389.625, ['x2'] = -195.375, ['y2'] = 442.375, ['action'] = -1, ['nxt'] = 6},
                {['id'] = 6, ['x1'] = -250.375, ['y1'] = 71.375, ['x2'] = -197.625, ['y2'] = 62.125, ['action'] = 1, ['nxt'] = 7},
                {['id'] = 7, ['x1'] = -380.125, ['y1'] = 5.625, ['x2'] = -391.625, ['y2'] = 58.375, ['action'] = -1, ['nxt'] = 8},
                {['id'] = 8, ['x1'] = -389.375, ['y1'] = 1.375, ['x2'] = -442.625, ['y2'] = -0.125, ['action'] = -1, ['nxt'] = 9},
                {['id'] = 9, ['x1'] = -325.125, ['y1'] = -58.375, ['x2'] = -314.875, ['y2'] = -5.625, ['action'] = 1, ['nxt'] = 10},
                {['id'] = 10, ['x1'] = -261.625, ['y1'] = -314.625, ['x2'] = -314.375, ['y2'] = -325.875, ['action'] = -1, ['nxt'] = 11},
                {['id'] = 11, ['x1'] = -197.125, ['y1'] = -325.625, ['x2'] = -186.375, ['y2'] = -378.375, ['action'] = -1, ['nxt'] = 1}
}

dirtOval_small = {
                {['id'] = 1, ['x1'] = 55.375, ['y1'] = -65.625, ['x2'] = 8.375, ['y2'] = -72.125, ['action'] = 0,  ['dir'] = 0, ['nxt'] = 2},
                {['id'] = 2,  ['x1'] = 55.625, ['y1'] = 0, ['x2'] = 8.875, ['y2'] = 1.875, ['action'] = -1,  ['dir'] = 3, ['nxt'] = 3},
                {['id'] = 3, ['x1'] = -131.875, ['y1'] = 55.625, ['x2'] = -130.375, ['y2'] = 9.625, ['action'] = -1,  ['dir'] = 2, ['nxt'] = 4},
                {['id'] = 4, ['x1'] = -183.625, ['y1'] = -190.125, ['x2'] = -136.875, ['y2'] = -194.125, ['action'] = -1,  ['dir'] = 1, ['nxt'] = 5},
                {['id'] = 5, ['x1'] = -1.375, ['y1'] = -247.625, ['x2'] = 3.625, ['y2'] = -200.625, ['action'] = -1,  ['dir'] = 0, ['nxt'] = 1},
}

metalOval_huge = {
                {['id'] = 1, ['x1'] = 135.875, ['y1'] = 252.875, ['x2'] = 183.875, ['y2'] = 254.625, ['action'] = 0,  ['dir'] = 0, ['nxt'] = 2},
                {['id'] = 2, ['x1'] = 135.625, ['y1'] = 646.625, ['x2'] = 184.125, ['y2'] = 642.875, ['action'] = -1,  ['dir'] = 3, ['nxt'] = 3},
                {['id'] = 3, ['x1'] = -326.625, ['y1'] = 647.625, ['x2'] = -328.625, ['y2'] = 696.125, ['action'] = -1,  ['dir'] = 2, ['nxt'] = 4},
                {['id'] = 4, ['x1'] = -327.625, ['y1'] = -646.625, ['x2'] = -376.125, ['y2'] = -649.625, ['action'] = -1,  ['dir'] = 1, ['nxt'] = 5},
                {['id'] = 5, ['x1'] = 134.625, ['y1'] = -647.625, ['x2'] = 139.375, ['y2'] = -696.125, ['action'] = -1,  ['dir'] = 0, ['nxt'] = 1},
}

--- GEN 6 Circuts
-- test
test = {
        {x2 = -134, x1 = -186, y2 = 184, id = 1, y1 = 184, next = 2, dir = 0, action = 0}, 
        {x2 = -132, x1 = -132, y2 = 326, id = 2, y1 = 326, next = 3, dir = 1, action = 1}, 
        {x2 = 134, x1 = 134, y2 = 324, id = 3, y1 = 324, next = 4, dir = 2, action = 1}, 
        {x2 = 132, x1 = 132, y2 = 186, id = 4, y1 = 186, next = 5, dir = 3, action = 1}, 
        {x2 = 122, x1 = 122, y2 = 132, id = 5, y1 = 132, next = 6, dir = 2, action = -1}, 
        {x2 = 68, x1 = 68, y2 = -262, id = 6, y1 = -262, next = 7, dir = 3, action = 1}, 
        {x2 = 58, x1 = 58, y2 = -260, id = 7, y1 = -260, next = 8, dir = 0, action = 1}, 
        {x2 = 4, x1 = 4, y2 = -186, id = 8, y1 = -186, next = 9, dir = 3, action = -1},
        {x2 = -6, x1 = -6, y2 = -188, id = 9, y1 = -188, next = 10, dir = 2, action = -1},
        {x2 = -60, x1 = -60, y2 = -262, id = 10, y1 = -262, next = 0, dir = 3, action = 1}, 
        {x2 = -134, x1 = -134, y2 = -260, id = 11, y1 = -260, next = 1, dir = 0, action = 1}}

beckwith_speedway = {
                {['id'] = 1, ['x1'] = -135.875, ['y1'] = 183.875, ['x2'] = -184.375, ['y2'] = 185.875, ['action'] = 0,  ['dir'] = 0, ['nxt'] = 2},
                {['id'] = 2, ['x1'] = -135.125, ['y1'] = 326.875, ['x2'] = -184.125, ['y2'] = 329.375, ['action'] = 1,  ['dir'] = 1, ['nxt'] = 3},
                {['id'] = 3, ['x1'] = 134.625, ['y1'] = 327.625, ['x2'] = 140.375, ['y2'] = 376.125, ['action'] = 1,  ['dir'] = 2, ['nxt'] = 4},
                {['id'] = 4, ['x1'] = 135.625, ['y1'] = 180.375, ['x2'] = 184.125, ['y2'] = 178.375, ['action'] = 1,  ['dir'] = 3, ['nxt'] = 5},
                {['id'] = 5, ['x1'] = 126.125, ['y1'] = 135.125, ['x2'] = 123.125, ['y2'] = 184.125, ['action'] = -1,  ['dir'] = 2, ['nxt'] = 6},
                {['id'] = 6, ['x1'] = 71.125, ['y1'] = -262.875, ['x2'] = 120.125, ['y2'] = -265.375, ['action'] = 1,  ['dir'] = 3, ['nxt'] = 7},
                {['id'] = 7, ['x1'] = 57.125, ['y1'] = -263.125, ['x2'] = 50.625, ['y2'] = -312.125, ['action'] = 1,  ['dir'] = 0, ['nxt'] = 8},
                {['id'] = 8, ['x1'] = 7.125, ['y1'] = -185.125, ['x2'] = 56.125, ['y2'] = -177.625, ['action'] = -1,  ['dir'] = 3, ['nxt'] = 9},
                {['id'] = 9, ['x1'] = -6.875, ['y1'] = -184.875, ['x2'] = -7.875, ['y2'] = -135.875, ['action'] = -1,  ['dir'] = 2, ['nxt'] = 10},
                {['id'] = 10, ['x1'] = -56.875, ['y1'] = -262.875, ['x2'] = -7.875, ['y2'] = -264.375, ['action'] = 1,  ['dir'] = 3, ['nxt'] = 11},
                {['id'] = 11, ['x1'] = -134.875, ['y1'] = -263.125, ['x2'] = -143.125, ['y2'] = -312.125, ['action'] = 1,  ['dir'] = 0, ['nxt'] = 1}
}
axolot_speedway = {
                    {['id'] = 1, ['x1'] = 135.625, ['y1'] = 188.875, ['x2'] = 184.125, ['y2'] = 190.125, ['action'] = 0,  ['dir'] = 0, ['nxt'] = 2},
                    {['id'] = 2, ['x1'] = 134.875, ['y1'] = 327.125, ['x2'] = 184.375, ['y2'] = 336.125, ['action'] = -1,  ['dir'] = 3, ['nxt'] = 3},
                    {['id'] = 3, ['x1'] = -7.125, ['y1'] = 326.875, ['x2'] = -11.375, ['y2'] = 376.375, ['action'] = -1,  ['dir'] = 2, ['nxt'] = 4},
                    {['id'] = 4, ['x1'] = -6.875, ['y1'] = 184.625, ['x2'] = -56.375, ['y2'] = 180.125, ['action'] = -1,  ['dir'] = 1, ['nxt'] = 5},
                    {['id'] = 5, ['x1'] = 6.625, ['y1'] = 135.625, ['x2'] = 10.125, ['y2'] = 184.375, ['action'] = 1,  ['dir'] = 2, ['nxt'] = 6},
                    {['id'] = 6, ['x1'] = 6.875, ['y1'] = 121.125, ['x2'] = 56.375, ['y2'] = 114.625, ['action'] = 1,  ['dir'] = 3, ['nxt'] = 7},
                    {['id'] = 7, ['x1'] = -135.375, ['y1'] = 70.875, ['x2'] = -149.625, ['y2'] = 120.375, ['action'] = -1,  ['dir'] = 2, ['nxt'] = 8},
                    {['id'] = 8, ['x1'] = -134.875, ['y1'] = -135.375, ['x2'] = -184.625, ['y2'] = -144.125, ['action'] = -1,  ['dir'] = 1, ['nxt'] = 9},
                    {['id'] = 9, ['x1'] = 71.375, ['y1'] = -134.875, ['x2'] = 82.125, ['y2'] = -184.625, ['action'] = -1,  ['dir'] = 0, ['nxt'] = 10},
                    {['id'] = 10, ['x1'] = 70.875, ['y1'] = -120.625, ['x2'] = 120.375, ['y2'] = -113.625, ['action'] = -1,  ['dir'] = 3, ['nxt'] = 11},
                    {['id'] = 11, ['x1'] = 57.125, ['y1'] = -70.875, ['x2'] = 39.625, ['y2'] = -120.375, ['action'] = 1,  ['dir'] = 0, ['nxt'] = 12},
                    {['id'] = 12, ['x1'] = 57.125, ['y1'] = -60.625, ['x2'] = 7.625, ['y2'] = -50.375, ['action'] = 1,  ['dir'] = 1, ['nxt'] = 13},
                    {['id'] = 13, ['x1'] = 135.375, ['y1'] = -6.875, ['x2'] = 150.375, ['y2'] = -56.375, ['action'] = -1,  ['dir'] = 0, ['nxt'] = 1}
}
crystal_valley = {
        {['id'] = 1, ['x1'] = 135.375, ['y1'] = 183.875, ['x2'] = 184.375, ['y2'] = 191.375, ['action'] = 0,  ['dir'] = 0, ['nxt'] = 2},
        {['id'] = 2, ['x1'] = 134.875, ['y1'] = 326.875, ['x2'] = 184.375, ['y2'] = 343.375, ['action'] = -1,  ['dir'] = 3, ['nxt'] = 3},
        {['id'] = 3, ['x1'] = -7.375, ['y1'] = 326.875, ['x2'] = -15.125, ['y2'] = 376.375, ['action'] = -1,  ['dir'] = 2, ['nxt'] = 4},
        {['id'] = 4, ['x1'] = -57.125, ['y1'] = 246.875, ['x2'] = -7.625, ['y2'] = 237.625, ['action'] = 1,  ['dir'] = 3, ['nxt'] = 5},
        {['id'] = 5, ['x1'] = -70.375, ['y1'] = 199.625, ['x2'] = -85.875, ['y2'] = 248.375, ['action'] = -1,  ['dir'] = 2, ['nxt'] = 6},
        {['id'] = 6, ['x1'] = -70.875, ['y1'] = 56.625, ['x2'] = -120.375, ['y2'] = 42.375, ['action'] = -1,  ['dir'] = 1, ['nxt'] = 7},
        {['id'] = 7, ['x1'] = -57.375, ['y1'] = 7.375, ['x2'] = -44.375, ['y2'] = 56.375, ['action'] = 1,  ['dir'] = 2, ['nxt'] = 8},
        {['id'] = 8, ['x1'] = -57.125, ['y1'] = -73.375, ['x2'] = -7.625, ['y2'] = -83.375, ['action'] = 1,  ['dir'] = 3, ['nxt'] = 9},
        {['id'] = 9, ['x1'] = -70.375, ['y1'] = -120.375, ['x2'] = -77.125, ['y2'] = -71.625, ['action'] = -1,  ['dir'] = 2, ['nxt'] = 10},
        {['id'] = 10, ['x1'] = -121.125, ['y1'] = -198.875, ['x2'] = -71.625, ['y2'] = -205.875, ['action'] = 1,  ['dir'] = 3, ['nxt'] = 11},
        {['id'] = 11, ['x1'] = -132.125, ['y1'] = -248.625, ['x2'] = -139.625, ['y2'] = -199.625, ['action'] = -1,  ['dir'] = 2, ['nxt'] = 12},
        {['id'] = 12, ['x1'] = -134.875, ['y1'] = -327.125, ['x2'] = -184.625, ['y2'] = -335.125, ['action'] = -1,  ['dir'] = 1, ['nxt'] = 13},
        {['id'] = 13, ['x1'] = -56.875, ['y1'] = -326.875, ['x2'] = -46.875, ['y2'] = -376.375, ['action'] = -1,  ['dir'] = 0, ['nxt'] = 14},
        {['id'] = 14, ['x1'] = -7.375, ['y1'] = -313.375, ['x2'] = -56.375, ['y2'] = -306.125, ['action'] = 1,  ['dir'] = 1, ['nxt'] = 15},
        {['id'] = 15, ['x1'] = 135.125, ['y1'] = -262.875, ['x2'] = 140.625, ['y2'] = -312.375, ['action'] = -1,  ['dir'] = 0, ['nxt'] = 16},
        {['id'] = 16, ['x1'] = 134.875, ['y1'] = -184.875, ['x2'] = 184.375, ['y2'] = -177.375, ['action'] = -1,  ['dir'] = 3, ['nxt'] = 17},
        {['id'] = 17, ['x1'] = 121.125, ['y1'] = -134.875, ['x2'] = 117.375, ['y2'] = -184.375, ['action'] = 1,  ['dir'] = 0, ['nxt'] = 18},
        {['id'] = 18, ['x1'] = 120.625, ['y1'] = -122.625, ['x2'] = 71.625, ['y2'] = -116.875, ['action'] = 1,  ['dir'] = 1, ['nxt'] = 19},
        {['id'] = 19, ['x1'] = 134.625, ['y1'] = -71.375, ['x2'] = 140.875, ['y2'] = -120.375, ['action'] = -1,  ['dir'] = 0, ['nxt'] = 1},
}
-- TODO: Figure out how to correctly set the x1/y1 of the start/finish node
salty_circut = {
        {x1 = -390, x2 = -442, y1 = 250, id = 1, nxt = 2, action = 0, y2 = 248, dir = 0},
        {x2 = -442, x1 = -388, y2 = 392, id = 2, nxt = 3, action = 1, y1 = 390, dir = 1},
        {x2 = 264, x1 = 262, y2 = 442, id = 3, nxt = 4, action = 1, y1 = 388, dir = 2},
        {x2 = 262, x1 = 316, y2 = 376, id = 4, nxt = 5, action = -1, y1 = 378, dir = 1},
        {x2 = 328, x1 = 326, y2 = 378, id = 5, nxt = 6, action = 1, y1 = 324, dir = 2},
        {x2 = 326, x1 = 380, y2 = 312, id = 6, nxt = 7, action = -1, y1 = 314, dir = 1},
        {x2 = 392, x1 = 390, y2 = 314, id = 7, nxt = 8, action = 1, y1 = 260, dir = 2},
        {x2 = 390, x1 = 444, y2 = 248, id = 8, nxt = 9, action = -1, y1 = 250, dir = 1},
        {x2 = 456, x1 = 454, y2 = 250, id = 9, nxt = 10, action = 1, y1 = 196, dir = 2},
        {x2 = 506, x1 = 452, y2 = -136, id = 10, nxt = 11, action = 1, y1 = -134, dir = 3},
        {x2 = -8, x1 = -6, y2 = -186, id = 11, nxt = 12, action = 1, y1 = -132, dir = 0},
        {x2 = -58, x1 = -4, y2 = 72, id = 12, nxt = 13, action = 1, y1 = 70, dir = 1},
        {x2 = 8, x1 = 6, y2 = 122, id = 13, nxt = 14, action = 1, y1 = 68, dir = 2},
        {x2 = 6, x1 = 60, y2 = 56, id = 14, nxt = 15, action = -1, y1 = 58, dir = 1},
        {x2 = 72, x1 = 70, y2 = 6, id = 15, nxt = 16, action = -1, y1 = 60, dir = 0},
        {x2 = 122, x1 = 68, y2 = 136, id = 16, nxt = 17, action = -1, y1 = 134, dir = 3},
        {x2 = -200, x1 = -198, y2 = 186, id = 17, nxt = 18, action = -1, y1 = 132, dir = 2},
        {x2 = -198, x1 = -252, y2 = -136, id = 18, nxt = 19, action = 1, y1 = -134, dir = 3},
        {x2 = -392, x1 = -390, y2 = -186, id = 19, nxt = 1, action = 1, y1 = -132, dir = 0}
}

misty_beach = {
        {x1 = -390, x2 = -442, y1 = 58, id = 1, nxt = 2, action = 0, y2 = 55.875, dir = 0}, 
        {x2 = -442, x1 = -388, y2 = 200, id = 2, nxt = 3, action = 1, y1 = 198, dir = 1},
        {x2 = -376, x1 = -378, y2 = 250, id = 3, nxt = 4, action = 1, y1 = 196, dir = 2},
        {x2 = -378, x1 = -324, y2 = -136, id = 4, nxt = 5, action = -1, y1 = -134, dir = 1},
        {x2 = -120, x1 = -122, y2 = -186, id = 5, nxt = 6, action = -1, y1 = -132, dir = 0},
        {x2 = -122, x1 = -68, y2 = -120, id = 6, nxt = 7, action = 1, y1 = -122, dir = 1},
        {x2 = -56, x1 = -58, y2 = -122, id = 7, nxt = 8, action = -1, y1 = -68, dir = 0},
        {x2 = -6, x1 = -60, y2 = -56, id = 8, nxt = 9, action = -1, y1 = -58, dir = 3},
        {x2 = -200, x1 = -198, y2 = -58, id = 9, nxt = 10, action = 1, y1 = -4, dir = 0},
        {x2 = -250, x1 = -196, y2 = 8, id = 10, nxt = 11, action = 1, y1 = 6, dir = 1},
        {x2 = 72, x1 = 70, y2 = 58, id = 11, nxt = 12, action = 1, y1 = 4, dir = 2},
        {x2 = 122, x1 = 68, y2 = -264, id = 12, nxt = 13, action = 1, y1 = -262, dir = 3},
        {x2 = -392, x1 = -390, y2 = -314, id = 13, nxt = 1, action = 1, y1 = -260, dir = 0}

}

midnight_moonway = {
        {x1 = -136, x2 = -184, y1 = 60, id = 1, nxt = 2, action = 0, y2 = 57.125, dir = 0},
        {x2 = -184, x1 = -134, y2 = 202, id = 2, nxt = 3, action = 1, y1 = 200, dir = 1},
        {x2 = 138, x1 = 136, y2 = 248, id = 3, nxt = 4, action = 1, y1 = 198, dir = 2},
        {x2 = 136, x1 = 186, y2 = -10, id = 4, nxt = 5, action = -1, y1 = -8, dir = 1},
        {x2 = 266, x1 = 264, y2 = -56, id = 5, nxt = 6, action = -1, y1 = -6, dir = 0},
        {x2 = 264, x1 = 314, y2 = 74, id = 6, nxt = 7, action = 1, y1 = 72, dir = 1},
        {x2 = 522, x1 = 520, y2 = 120, id = 7, nxt = 8, action = 1, y1 = 70, dir = 2},
        {x2 = 568, x1 = 518, y2 = -138, id = 8, nxt = 9, action = 1, y1 = -136, dir = 3},
        {x2 = 118, x1 = 120, y2 = -136, id = 9, nxt = 10, action = -1, y1 = -186, dir = 2},
        {x2 = 120, x1 = 70, y2 = -202, id = 10, nxt = 11, action = 1, y1 = -200, dir = 3},
        {x2 = -138, x1 = -136, y2 = -248, id = 11, nxt = 1, action = 1, y1 = -198, dir = 0}
}

mystic_raceway = {
        {x2 = 56, x1 = 8, y2 = 124, id = 1, nxt = 2, action = 0, y1 = 121.125, dir = 0},
        {x2 = 56, x1 = 6, y2 = 202, id = 2, nxt = 3, action = -1, y1 = 200, dir = 3},
        {x2 = -10, x1 = -8, y2 = 248, id = 3, nxt = 4, action = -1, y1 = 198, dir = 2},
        {x2 = -56, x1 = -6, y2 = -202, id = 4, nxt = 5, action = -1, y1 = -200, dir = 1},
        {x2 = 138, x1 = 136, y2 = -248, id = 5, nxt = 6, action = -1, y1 = -198, dir = 0},
        {x2 = 136, x1 = 186, y2 = -182, id = 6, nxt = 7, action = 1, y1 = -184, dir = 1},
        {x2 = 394, x1 = 392, y2 = -184, id = 7, nxt = 8, action = -1, y1 = -134, dir = 0},
        {x2 = 440, x1 = 390, y2 = -118, id = 8, nxt = 9, action = -1, y1 = -120, dir = 3},
        {x2 = 182, x1 = 184, y2 = -120, id = 9, nxt = 10, action = 1, y1 = -70, dir = 0},
        {x2 = 184, x1 = 134, y2 = 202, id = 10, nxt = 11, action = -1, y1 = 200, dir = 3},
        {x2 = 118, x1 = 120, y2 = 248, id = 11, nxt = 12, action = -1, y1 = 198, dir = 2},
        {x2 = 120, x1 = 70, y2 = -138, id = 12, nxt = 13, action = 1, y1 = -136, dir = 3},
        {x2 = 54, x1 = 56, y2 = -184, id = 13, nxt = 1, action = 1, y1 = -134, dir = 0}
}

Minty_motorway = {
        {x2 = 120, x1 = 72, y2 = 124, id = 1, nxt = 2, action = 0, y1 = 121.125, dir = 0},
        {x2 = 120, x1 = 70, y2 = 266, id = 2, nxt = 3, action = -1, y1 = 264, dir = 3},
        {x2 = 54, x1 = 56, y2 = 264, id = 3, nxt = 4, action = 1, y1 = 314, dir = 0},
        {x2 = 8, x1 = 58, y2 = 394, id = 4, nxt = 5, action = 1, y1 = 392, dir = 1},
        {x2 = 202, x1 = 200, y2 = 440, id = 5, nxt = 6, action = 1, y1 = 390, dir = 2},
        {x2 = 200, x1 = 250, y2 = 246, id = 6, nxt = 7, action = -1, y1 = 248, dir = 1},
        {x2 = 266, x1 = 264, y2 = 248, id = 7, nxt = 8, action = 1, y1 = 198, dir = 2},
        {x2 = 264, x1 = 314, y2 = -74, id = 8, nxt = 9, action = -1, y1 = -72, dir = 1},
        {x2 = 330, x1 = 328, y2 = -72, id = 9, nxt = 10, action = 1, y1 = -122, dir = 2},
        {x2 = 376, x1 = 326, y2 = -138, id = 10, nxt = 11, action = 1, y1 = -136, dir = 3},
        {x2 = 246, x1 = 248, y2 = -184, id = 11, nxt = 12, action = 1, y1 = -134, dir = 0},
        {x2 = 248, x1 = 198, y2 = -118, id = 12, nxt = 13, action = -1, y1 = -120, dir = 3},
        {x2 = 182, x1 = 184, y2 = -72, id = 13, nxt = 14, action = -1, y1 = -122, dir = 2},
        {x2 = 184, x1 = 134, y2 = -266, id = 14, nxt = 15, action = 1, y1 = -264, dir = 3},
        {x2 = 118, x1 = 120, y2 = -312, id = 15, nxt = 1, action = 1, y1 = -262, dir = 0}
}
-- GEN 7 Circuts
beckwith_nodes = {{entryDir = {-1, 0}, exitDir = {0, 1}, exit = {-98, 366}, maxSpeed = 3500, entry = {-172, 292}, id = 1},
                 {entryDir = {0, 1}, exitDir = {1, 0}, exit = {174, 306}, maxSpeed = 3500, entry = {100, 364}, id = 2}, 
                 {entryDir = {1, 0}, exitDir = {0, -1}, exit = {108, 146}, maxSpeed = 3500, entry = {172, 204}, id = 3},
                 {entryDir = {0, -1}, exitDir = {1, 0}, exit = {84, 110}, maxSpeed = 3500, entry = {148, 172}, id = 4}, 
                 {entryDir = {1, 0}, exitDir = {0, -1}, exit = {44, -300}, maxSpeed = 2700, entry = {108, -240}, id = 5},
                 {entryDir = {0, -1}, exitDir = {-1, 0}, exit = {20, -234}, maxSpeed = 3500, entry = {84, -300}, id = 6},
                 {entryDir = {-1, 0}, exitDir = {0, -1}, exit = {-20, -148}, maxSpeed = 2700, entry = {44, -212}, id = 7},
                 {entryDir = {0, -1}, exitDir = {1, 0}, exit = {-44, -214}, maxSpeed = 3500, entry = {20, -148}, id = 8}, 
                 {entryDir = {1, 0}, exitDir = {0, -1}, exit = {-86, -300}, maxSpeed = 3500, entry = {-20, -236}, id = 9}, 
                 {entryDir = {0, -1}, exitDir = {-1, 0}, exit = {-172, -226}, maxSpeed = 3500, entry = {-108, -300}, id = 10}
                }


BeckwithCams= {
                {['id'] = 1, ['x'] = -136.125, ['y'] = 188.875, ['z'] = 20,  ['angle'] = 2.5, ['zoom'] = 60}
    }

AxolotCams= {
        {['id'] = 1, ['x'] = 134.456, ['y'] = 191.128, ['z'] = 5,  ['angle'] = 0, ['zoom'] = 1}
}
CrystalCams = {
        {['id'] = 1, ['x'] = 134.559, ['y'] = 187.34, ['z'] = 5,  ['angle'] = 0, ['zoom'] = 1}
}
SaltyCams = {
        {['id'] = 1, ['x'] = -441.493, ['y'] = 248.974, ['z'] = 5,  ['angle'] = 0, ['zoom'] = 1}
}
MistyCams = {
        {['id'] = 1, ['x'] = -441.065, ['y'] = 62.875, ['z'] = 5,  ['angle'] = 0, ['zoom'] = 1}
}
MoonwayCams = {
        {['id'] = 1, ['x'] = -184.365, ['y'] = 58.408, ['z'] = 6,  ['angle'] = 0, ['zoom'] = 1}
}
MysticCams = {
        {['id'] = 1, ['x'] = 7.235, ['y'] = 121.859, ['z'] = 6,  ['angle'] = 0, ['zoom'] = 1}
}
MintyCams = {
        {['id'] = 1, ['x'] = 71.40, ['y'] = 121.836, ['z'] = 6,  ['angle'] = 0, ['zoom'] = 1}
}
mapSet = {LegacyAxolotSpeedway,
saltyCircut,
dirtOval_small,
metalOval_huge,
beckwith_speedway,
axolot_speedway,
crystal_valley,
salty_circut,
misty_beach,
midnight_moonway,
mystic_raceway,
Minty_motorway}

gen7mapSet = {LegacyAxolotSpeedway,saltyCircut,dirtOval_small,metalOval_huge,beckwith_nodes,axolot_speedway,crystal_valley}
cameraMaps = {axolotSpeedCams,axolotSpeedCams,axolotSpeedCams,axolotSpeedCams,BeckwithCams,AxolotCams,CrystalCams,AxolotCams,SaltyCams,MistyCams,MoonwayCams,MysticCams,MintyCams}
sm.cameraMaps = {['curID'] = 13, ['maps'] = cameraMaps}