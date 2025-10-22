package game

rows_by_level := [?][16]Row {
	rows_level_1,
	rows_level_2,
	rows_level_3,
	rows_level_4,
	rows_level_5,
}


entities_by_level := [?][]Entity {
	entities_level_1[:],
	entities_level_2[:],
	entities_level_3[:],
	entities_level_4[:],
	entities_level_5[:],
}


rows_level_1 := [16]Row {
	{start_x = 0,    speed = 0},
	{start_x = 0,    speed = 0},
	{start_x = 0,    speed = 0},
	{start_x = -9,   speed = 1.2},
	{start_x = -3.5, speed = -1.5},
	{start_x = -10,  speed = 3},
	{start_x = -6,   speed = 0.8},
	{start_x = -2,   speed = -1.5},
	{start_x = 0,    speed = 0},
	{start_x = -2,   speed = -1.5},
	{start_x = -1,   speed = 1},
	{start_x = -1,   speed = -0.8},
	{start_x = -1,   speed = 0.6},
	{start_x = -1,   speed = -0.6},
	{start_x = 0,    speed = 0},
	{start_x = 0,    speed = 0},
}


entities_level_1 := [?]Entity {
    { rectangle = {0    ,  3, 4, 1},   speed = 1.2,    row_id = 3,  sprite_data   = .Medium_Log,                             collision_behavior           = .Move_Frogger},
    { rectangle = {6    ,  3, 4, 1},   speed = 1.2,    row_id = 3,  sprite_data   = .Medium_Log,                             collision_behavior           = .Move_Frogger},
    { rectangle = {12   , 3, 4, 1},   speed  = 1.2,    row_id = 3,  sprite_data   = .Medium_Log,                             collision_behavior           = .Move_Frogger},
    { rectangle = {18   , 3, 4, 1},   speed  = 1.2,    row_id = 3,  sprite_data   = .Medium_Log,                             collision_behavior           = .Move_Frogger},
    { rectangle = {2    ,  4, 1, 1},   speed = -1.5,   row_id = 4, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {3    ,  4, 1, 1},   speed = -1.5,   row_id = 4, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {6    ,  4, 1, 1},   speed = -1.5,   row_id = 4, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {7    ,  4, 1, 1},   speed = -1.5,   row_id = 4, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {10   , 4, 1, 1},   speed  = -1.5,   row_id = 4, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {11   , 4, 1, 1},   speed  = -1.5,   row_id = 4, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {15.5 , 4, 1, 1}, speed    = -1.5,   row_id = 4, sprite_data     = Animation_Player_Name.Diving_Turtle_0, collision_behavior             = .Move_Frogger },
    { rectangle = {16.5 , 4, 1, 1}, speed    = -1.5,   row_id = 4, sprite_data     = Animation_Player_Name.Diving_Turtle_0, collision_behavior             = .Move_Frogger },
    { rectangle = {0    ,  5, 6, 1},   speed = 3,     row_id =  5,   sprite_data = .Long_Log,                               collision_behavior           = .Move_Frogger},
    { rectangle = {8    ,  5, 6, 1},   speed = 3,     row_id =  5,   sprite_data = .Long_Log,                               collision_behavior           = .Move_Frogger},
    { rectangle = {16   , 5, 6, 1},   speed  = 3,     row_id =  5,   sprite_data = .Long_Log,                               collision_behavior           = .Move_Frogger},
    { rectangle = {0    ,  6, 3, 1},   speed = 0.8,   row_id =  6,   sprite_data   = .Short_Log,                              collision_behavior           = .Move_Frogger},
    { rectangle = {5    ,  6, 3, 1},   speed = 0.8,   row_id =  6,   sprite_data   = .Short_Log,                              collision_behavior           = .Move_Frogger},
    { rectangle = {10   , 6, 3, 1},   speed  = 0.8,   row_id =  6,   sprite_data   = .Short_Log,                              collision_behavior           = .Move_Frogger},
    { rectangle = {15   , 6, 3, 1},   speed  = 0.8,   row_id =  6,   sprite_data   = .Short_Log,                              collision_behavior           = .Move_Frogger},
    { rectangle = {0    ,  7, 1, 1},   speed = -1.5,  row_id =  7, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {1    ,  7, 1, 1},   speed = -1.5,  row_id =  7, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {2    ,  7, 1, 1},   speed = -1.5,  row_id =  7, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {4    ,  7, 1, 1},   speed = -1.5,  row_id =  7, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {5    ,  7, 1, 1},   speed = -1.5,  row_id =  7, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {6    ,  7, 1, 1},   speed = -1.5,  row_id =  7, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {8    ,  7, 1, 1},   speed = -1.5,  row_id =  7, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {9    ,  7, 1, 1},   speed = -1.5,  row_id =  7, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {10   , 7, 1, 1},   speed  = -1.5,  row_id =  7, sprite_data     = Animation_Player_Name.Regular_Turtle,              collision_behavior = .Move_Frogger},
    { rectangle = {12   ,   7, 1, 1}, speed  = -1.5,  row_id =  7, sprite_data     = Animation_Player_Name.Diving_Turtle_1, collision_behavior             = .Move_Frogger },
    { rectangle = {13   ,   7, 1, 1}, speed  = -1.5,  row_id =  7, sprite_data     = Animation_Player_Name.Diving_Turtle_1, collision_behavior             = .Move_Frogger },
    { rectangle = {14   ,   7, 1, 1}, speed  = -1.5,  row_id =  7, sprite_data     = Animation_Player_Name.Diving_Turtle_1, collision_behavior             = .Move_Frogger },
    { rectangle = {1    ,   9, 2, 1},  speed = -1.5  , row_id = 9, sprite_data     = .Truck,                                  collision_behavior           = .Kill_Frogger},
    { rectangle = {6.5  , 9, 2, 1},  speed   = -1.5  , row_id = 9, sprite_data     = .Truck,                                  collision_behavior           = .Kill_Frogger},
    { rectangle = {1    ,  10, 1, 1},  speed = 1  ,    row_id = 10, sprite_data   = .Racecar,                                collision_behavior           = .Kill_Frogger},
    { rectangle = {10   , 11, 1, 1},  speed  = -0.8  , row_id = 11, sprite_data     = .Purple_Car,                             collision_behavior           = .Kill_Frogger},
    { rectangle = {6    ,  11, 1, 1},  speed = -0.8  , row_id = 11, sprite_data     = .Purple_Car,                             collision_behavior           = .Kill_Frogger},
    { rectangle = {2    ,  11, 1, 1},  speed = -0.8  , row_id = 11, sprite_data     = .Purple_Car,                             collision_behavior           = .Kill_Frogger},
    { rectangle = {5    ,  12, 1, 1},  speed = 0.6  ,  row_id = 12, sprite_data     = .Bulldozer,                              collision_behavior           = .Kill_Frogger},
    { rectangle = {9    ,  12, 1, 1},  speed = 0.6  ,  row_id = 12, sprite_data     = .Bulldozer,                              collision_behavior           = .Kill_Frogger},
    { rectangle = {13   , 12, 1, 1},  speed  = 0.6  ,  row_id = 12, sprite_data     = .Bulldozer,                              collision_behavior           = .Kill_Frogger},
    { rectangle = {10   , 13, 1, 1},  speed  = -0.6  , row_id = 13, sprite_data     = .Taxi,                                   collision_behavior           = .Kill_Frogger},
    { rectangle = {6    ,  13, 1, 1},  speed = -0.6  , row_id = 13, sprite_data     = .Taxi,                                   collision_behavior           = .Kill_Frogger},
    { rectangle = {2    ,  13, 1, 1},  speed = -0.6  , row_id = 13, sprite_data     = .Taxi,                                   collision_behavior           = .Kill_Frogger},
}
// 15

rows_level_2 := [16]Row {
	{start_x = 0,     speed = 0},
	{start_x = 0,     speed = 0},
	{start_x = 0,     speed = 0},
	{start_x = -15,   speed = 1.2},
	{start_x = -2.5,  speed = -2},
	{start_x = -18,   speed = 2},
	{start_x = -3,    speed = 0.8},
	{start_x = -2,    speed = -2},
	{start_x = 0,     speed = 0},
	{start_x = -3,    speed = -1.5},
	{start_x = -1,    speed = 1},
	{start_x = -4,    speed = -2},
	{start_x = -2,    speed = 2},
	{start_x = -4,    speed = -2},
	{start_x = 0,     speed = 0},
	{start_x = 0,     speed = 0},
}

entities_level_2 := [?]Entity {
    { rectangle = {0,  3, 4, 1},     speed = 1.2,  row_id = 3,  collision_behavior = .Move_Frogger,  sprite_data = .Medium_Log, },
    { rectangle = {6,  3, 4, 1},     speed = 1.2,  row_id = 3,  collision_behavior = .Move_Frogger,  sprite_data = .Medium_Log, },
    { rectangle = {12, 3, 4, 1},     speed = 1.2,  row_id = 3,  collision_behavior = .Move_Frogger,  sprite_data = .Medium_Log, },
    { rectangle = {18, 3, 4, 1},     speed = 1.2,  row_id = 3,  collision_behavior = .Move_Frogger,  sprite_data = .Medium_Log, },
    { rectangle = {24, 3, 3, 1},     speed = 1.2,  row_id = 3,  collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Alligator, },
    { rectangle = {2,  4, 1, 1},     speed = -2,   row_id = 4,  collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {3,  4, 1, 1},     speed = -2,   row_id = 4,  collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {5,  4, 1, 1},     speed = -2,   row_id = 4,  collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {6,  4, 1, 1},     speed = -2,   row_id = 4,  collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {8, 4, 1, 1},     speed = -2,    row_id = 4,  collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {9, 4, 1, 1},     speed = -2,    row_id = 4,  collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {11, 4, 1, 1},     speed = -2,   row_id = 4, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {12, 4, 1, 1},     speed = -2,   row_id = 4, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {15.5, 4, 1, 1},   speed = -2,   row_id = 4, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_0,  },
    { rectangle = {16.5, 4, 1, 1},   speed = -2,   row_id = 4, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_0,  },
    { rectangle = {0,  5, 6, 1},     speed = 2,    row_id = 5,  collision_behavior = .Move_Frogger,  sprite_data = .Long_Log, },
    { rectangle = {16,  5, 6, 1},    speed = 2,    row_id = 5,  collision_behavior = .Move_Frogger,  sprite_data = .Long_Log, },
    { rectangle = {0,    6, 3, 1},   speed = 0.8,  row_id = 6,   collision_behavior = .Move_Frogger,  sprite_data = .Short_Log, },
    { rectangle = {5,    6, 3, 1},   speed = 0.8,  row_id = 6,   collision_behavior = .Move_Frogger,  sprite_data = .Short_Log, },
    { rectangle = {10,   6, 3, 1},   speed = 0.8,  row_id = 6,   collision_behavior = .Move_Frogger,  sprite_data = .Short_Log, },
    { rectangle = {2,    7, 1, 1},   speed = -2,   row_id = 7, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {3,    7, 1, 1},   speed = -2,   row_id = 7, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {4,    7, 1, 1},   speed = -2,   row_id = 7, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {8,    7, 1, 1},   speed = -2,   row_id = 7, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {9,    7, 1, 1},   speed = -2,   row_id = 7, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {10,   7, 1, 1},   speed = -2,   row_id = 7, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {12,   7, 1, 1},   speed = -2,   row_id = 7, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_1,  },
    { rectangle = {13,   7, 1, 1},   speed = -2,   row_id = 7, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_1,  },
    { rectangle = {14,   7, 1, 1},   speed = -2,   row_id = 7, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_1,  },
    { rectangle = {1,   9, 2, 1},  speed = -1.5,   row_id = 9, collision_behavior = .Kill_Frogger,  sprite_data = .Truck, },
    { rectangle = {6.5, 9, 2, 1},  speed = -1.5,   row_id = 9, collision_behavior = .Kill_Frogger,  sprite_data = .Truck, },
    { rectangle = {12, 9, 2, 1},  speed = -1.5,    row_id = 9, collision_behavior = .Kill_Frogger,  sprite_data = .Truck, },
    { rectangle = {1,  10, 1, 1},  speed = 1  ,    row_id = 10, collision_behavior = .Kill_Frogger,  sprite_data = .Racecar, },
    { rectangle = {3.5,  10, 1, 1},  speed = 1  ,  row_id = 10,  collision_behavior = .Kill_Frogger,  sprite_data = .Racecar, },
    { rectangle = {0, 11, 1, 1},  speed = -2  ,    row_id = 11,   collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {2.5,  11, 1, 1},  speed = -2  , row_id = 11,   collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {6.5,  11, 1, 1},  speed = -2  , row_id = 11,   collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {12,  11, 1, 1},  speed = -2  ,  row_id = 11,   collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {0,  12, 1, 1},  speed = 2  ,    row_id = 12, collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {4,  12, 1, 1},  speed = 2  ,    row_id = 12, collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {8, 12, 1, 1},  speed = 2  ,     row_id = 12, collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {12, 12, 1, 1},  speed = 2  ,    row_id = 12, collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {0, 13, 1, 1},  speed = -2  ,    row_id = 13,   collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
    { rectangle = {2.5,  13, 1, 1},  speed = -2  , row_id = 13,   collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
    { rectangle = {6.5,  13, 1, 1},  speed = -2  , row_id = 13,   collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
    { rectangle = {12,  13, 1, 1},  speed = -2  ,  row_id = 13,   collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
}

// 17


rows_level_3 := [16]Row {
	{start_x = 0,   speed = 0},
	{start_x = 0,   speed = 0},
	{start_x = 0,   speed = 0},
	{start_x = -18, speed = 1.2},
	{start_x = -4,  speed = -2},
	{start_x = -18, speed = 2},
	{start_x = -3,  speed = 0.8},
	{start_x = -3,  speed = -3.5},
	{start_x = 0,   speed = 0},
	{start_x = -3,  speed = -1.5},
	{start_x = -1,  speed = 3},
	{start_x = -4,  speed = -3},
	{start_x = -1,  speed = 2},
	{start_x = -2,  speed = -1.5},
	{start_x = 0,   speed = 0},
	{start_x = 0,   speed = 0},
}

entities_level_3 := [?]Entity {
    { rectangle = {0.5, 3, 3, 1},     speed = 1.2,   row_id = 3,    collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Alligator, },
    { rectangle = {11,  3, 4, 1},     speed = 1.2,   row_id = 3,    collision_behavior = .Move_Frogger,  sprite_data = .Medium_Log, },
    { rectangle = {17,  3, 4, 1},     speed = 1.2,   row_id = 3,    collision_behavior = .Move_Frogger,  sprite_data = .Medium_Log, },
    { rectangle = {27.5, 3, 4, 1},    speed = 1.2,   row_id = 3,    collision_behavior = .Move_Frogger,  sprite_data = .Medium_Log, },
    { rectangle = {1,  4, 1, 1},     speed = -2,     row_id = 4,    collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {2,  4, 1, 1},     speed = -2,     row_id = 4,    collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {5.5, 4, 1, 1},     speed = -2,    row_id = 4,     collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {6.5, 4, 1, 1},     speed = -2,    row_id = 4,     collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {10, 4, 1, 1},   speed = -2,       row_id = 4,     collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_0,  },
    { rectangle = {11, 4, 1, 1},   speed = -2,       row_id = 4,     collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_0,  },
    { rectangle = {14.5,  4, 1, 1},     speed = -2,  row_id = 4, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {15.5,  4, 1, 1},     speed = -2,  row_id = 4, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {0,  5, 6, 1},     speed = 2,      row_id = 5,     collision_behavior = .Move_Frogger,  sprite_data = .Long_Log, },
    { rectangle = {16,  5, 6, 1},    speed = 2,      row_id = 5,     collision_behavior = .Move_Frogger,  sprite_data = .Long_Log, },
    { rectangle = {0,    6, 3, 1},   speed = 0.8,    row_id = 6,      collision_behavior = .Move_Frogger,  sprite_data = .Short_Log, },
    { rectangle = {5,    6, 3, 1},   speed = 0.8,    row_id = 6,      collision_behavior = .Move_Frogger,  sprite_data = .Short_Log, },
    { rectangle = {10,   6, 3, 1},   speed = 0.8,    row_id = 6,      collision_behavior = .Move_Frogger,  sprite_data = .Short_Log, },
    { rectangle = {0,   7, 1, 1},   speed = -3.5,    row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_1,  },
    { rectangle = {1,   7, 1, 1},   speed = -3.5,    row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_1,  },
    { rectangle = {2,   7, 1, 1},   speed = -3.5,    row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_1,  },
    { rectangle = {5,    7, 1, 1},   speed = -3.5,   row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {6,    7, 1, 1},   speed = -3.5,   row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {7,    7, 1, 1},   speed = -3.5,   row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {10,    7, 1, 1},   speed = -3.5,  row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {11,    7, 1, 1},   speed = -3.5,  row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {12,   7, 1, 1},   speed = -3.5,   row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {1,   9, 2, 1},  speed = -1.5,     row_id = 9,      collision_behavior = .Kill_Frogger,  sprite_data = .Truck, },
    { rectangle = {6.5, 9, 2, 1},  speed = -1.5,     row_id = 9,      collision_behavior = .Kill_Frogger,  sprite_data = .Truck, },
    { rectangle = {12, 9, 2, 1},  speed = -1.5,      row_id = 9,      collision_behavior = .Kill_Frogger,  sprite_data = .Truck, },
    { rectangle = {1,  10, 1, 1},  speed = 3  ,      row_id = 10,     collision_behavior = .Kill_Frogger,  sprite_data = .Racecar, },
    { rectangle = {5.5,  10, 1, 1},  speed = 3  ,    row_id = 10,    collision_behavior = .Kill_Frogger,  sprite_data = .Racecar, },
    { rectangle = {0, 11, 1, 1},     speed = -3  ,   row_id = 11,        collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {2.5,  11, 1, 1},  speed = -3  ,   row_id = 11,     collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {6.5,  11, 1, 1},  speed = -3  ,   row_id = 11,     collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {12,  11, 1, 1},   speed = -3  ,   row_id = 11,      collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {0,  12, 1, 1},  speed = 2  ,      row_id = 12,     collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {4,  12, 1, 1},  speed = 2  ,      row_id = 12,     collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {8, 12, 1, 1},  speed = 2  ,       row_id = 12,     collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {12, 12, 1, 1},  speed = 2  ,      row_id = 12,     collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {0, 13, 1, 1},     speed = -1.5  , row_id = 13,     collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
    { rectangle = {4,  13, 1, 1},  speed = -1.5  ,   row_id = 13,     collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
    { rectangle = {8,  13, 1, 1},  speed = -1.5  ,   row_id = 13,     collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
    { rectangle = {12,  13, 1, 1},   speed = -1.5  , row_id = 13,     collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
}

// 14

rows_level_4 := [16]Row {
	{start_x = 0,   speed = 0},
	{start_x = 0,   speed = 0},
	{start_x = 0,   speed = 0},
	{start_x = -18, speed = 2},
	{start_x = -4,  speed = -2},
	{start_x = -18, speed = 2},
	{start_x = -10,  speed = 1.5},
	{start_x = -3,  speed = -3.5},
	{start_x = 0,   speed = 0},
	{start_x = -4.5,  speed = -1.5},
	{start_x = -5,  speed = 6},
	{start_x = -4,  speed = -3},
	{start_x = -1,  speed = 2},
	{start_x = -4,  speed = -1.5},
	{start_x = 0,   speed = 0},
	{start_x = 0,   speed = 0},
}

entities_level_4 := [?]Entity {
    { rectangle = {0.5, 3, 3, 1},     speed = 1.2,   row_id = 3,    collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Alligator, },
    { rectangle = {11,  3, 4, 1},     speed = 1.2,   row_id = 3,    collision_behavior = .Move_Frogger,  sprite_data = .Medium_Log, },
    { rectangle = {17,  3, 4, 1},     speed = 1.2,   row_id = 3,    collision_behavior = .Move_Frogger,  sprite_data = .Medium_Log, },
    { rectangle = {27.5, 3, 4, 1},    speed = 1.2,   row_id = 3,    collision_behavior = .Move_Frogger,  sprite_data = .Medium_Log, },
    { rectangle = {1,  4, 1, 1},     speed = -2,     row_id = 4,    collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {2,  4, 1, 1},     speed = -2,     row_id = 4,    collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    // TODO(jalfonso): this gap is not supposed to be as big
    { rectangle = {10, 4, 1, 1},   speed = -2,       row_id = 4,     collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_0,  },
    { rectangle = {11, 4, 1, 1},   speed = -2,       row_id = 4,     collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_0,  },
    { rectangle = {14.5,  4, 1, 1},     speed = -2,  row_id = 4, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {15.5,  4, 1, 1},     speed = -2,  row_id = 4, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {0,  5, 6, 1},     speed = 2,      row_id = 5,     collision_behavior = .Move_Frogger,  sprite_data = .Long_Log, },
    { rectangle = {16,  5, 6, 1},    speed = 2,      row_id = 5,     collision_behavior = .Move_Frogger,  sprite_data = .Long_Log, },
    { rectangle = {0,    6, 3, 1},   speed = 0.8,    row_id = 6,      collision_behavior = .Move_Frogger,  sprite_data = .Short_Log, },
    { rectangle = {8,    6, 3, 1},   speed = 0.8,    row_id = 6,      collision_behavior = .Move_Frogger,  sprite_data = .Short_Log, },
    { rectangle = {17,   6, 3, 1},   speed = 0.8,    row_id = 6,      collision_behavior = .Move_Frogger,  sprite_data = .Short_Log, },
    { rectangle = {0,   7, 1, 1},   speed = -3.5,    row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_1,  },
    { rectangle = {1,   7, 1, 1},   speed = -3.5,    row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_1,  },
    { rectangle = {2,   7, 1, 1},   speed = -3.5,    row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_1,  },
    { rectangle = {5,    7, 1, 1},   speed = -3.5,   row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {6,    7, 1, 1},   speed = -3.5,   row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {7,    7, 1, 1},   speed = -3.5,   row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {10,    7, 1, 1},   speed = -3.5,  row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {11,    7, 1, 1},   speed = -3.5,  row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {12,   7, 1, 1},   speed = -3.5,   row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {0,   9, 2, 1},  speed = -1.5,     row_id = 9,      collision_behavior = .Kill_Frogger,  sprite_data = .Truck, },
    { rectangle = {4.5, 9, 2, 1},  speed = -1.5,     row_id = 9,      collision_behavior = .Kill_Frogger,  sprite_data = .Truck, },
    { rectangle = {9, 9, 2, 1},  speed = -1.5,      row_id = 9,      collision_behavior = .Kill_Frogger,  sprite_data = .Truck, },
    { rectangle = {13.5, 9, 2, 1},  speed = -1.5,      row_id = 9,      collision_behavior = .Kill_Frogger,  sprite_data = .Truck, },
    { rectangle = {1,  10, 1, 1},  speed = 3  ,      row_id = 10,     collision_behavior = .Kill_Frogger,  sprite_data = .Racecar, },
    { rectangle = {5.5,  10, 1, 1},  speed = 3  ,    row_id = 10,    collision_behavior = .Kill_Frogger,  sprite_data = .Racecar, },
    { rectangle = {10,  10, 1, 1},  speed = 3  ,    row_id = 10,    collision_behavior = .Kill_Frogger,  sprite_data = .Racecar, },
    { rectangle = {0, 11, 1, 1},     speed = -3  ,   row_id = 11,        collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {2.5,  11, 1, 1},  speed = -3  ,   row_id = 11,     collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {6.5,  11, 1, 1},  speed = -3  ,   row_id = 11,     collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {12,  11, 1, 1},   speed = -3  ,   row_id = 11,      collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {0,  12, 1, 1},  speed = 2  ,      row_id = 12,     collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {4,  12, 1, 1},  speed = 2  ,      row_id = 12,     collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {8, 12, 1, 1},  speed = 2  ,       row_id = 12,     collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {12, 12, 1, 1},  speed = 2  ,      row_id = 12,     collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {0, 13, 1, 1},     speed = -1.5  , row_id = 13,     collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
    { rectangle = {5,  13, 1, 1},  speed = -1.5  ,   row_id = 13,     collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
    { rectangle = {10,  13, 1, 1},  speed = -1.5  ,   row_id = 13,     collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
    { rectangle = {15,  13, 1, 1},   speed = -1.5  , row_id = 13,     collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
}

rows_level_5 := [16]Row {
	{start_x = 0,   speed = 0},
	{start_x = 0,   speed = 0},
	{start_x = 0,   speed = 0},
	{start_x = -18, speed = 2},
	{start_x = -6,  speed = -2},
	{start_x = -18, speed = 2},
	{start_x = -10,  speed = 1.5},
	{start_x = -3,  speed = -2},
	{start_x = 0,   speed = 0},
	{start_x = -6,  speed = -1.5},
	{start_x = -5,  speed = 6},
	{start_x = -4,  speed = -3},
	{start_x = -2,  speed = 2},
	{start_x = -4,  speed = -1.5},
	{start_x = 0,   speed = 0},
	{start_x = 0,   speed = 0},
}

entities_level_5 := [?]Entity {
    { rectangle = {0.5, 3, 3, 1},     speed = 1.2,   row_id = 3,    collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Alligator, },
    { rectangle = {17,  3, 4, 1},     speed = 1.2,   row_id = 3,    collision_behavior = .Move_Frogger,  sprite_data = .Medium_Log, },
    { rectangle = {0,  4, 1, 1},     speed = -2,     row_id = 4,    collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {1,  4, 1, 1},     speed = -2,     row_id = 4,    collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {6.5, 4, 1, 1},   speed = -2,       row_id = 4,     collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_0,  },
    { rectangle = {7.5, 4, 1, 1},   speed = -2,       row_id = 4,     collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_0,  },
    { rectangle = {13,  4, 1, 1},     speed = -2,  row_id = 4, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {14,  4, 1, 1},     speed = -2,  row_id = 4, collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {0,  5, 6, 1},     speed = 2,      row_id = 5,     collision_behavior = .Move_Frogger,  sprite_data = .Long_Log, },
    { rectangle = {16,  5, 6, 1},    speed = 2,      row_id = 5,     collision_behavior = .Move_Frogger,  sprite_data = .Long_Log, },
    { rectangle = {0,    6, 3, 1},   speed = 0.8,    row_id = 6,      collision_behavior = .Move_Frogger,  sprite_data = .Short_Log, },
    { rectangle = {8,    6, 3, 1},   speed = 0.8,    row_id = 6,      collision_behavior = .Move_Frogger,  sprite_data = .Short_Log, },
    { rectangle = {17,   6, 3, 1},   speed = 0.8,    row_id = 6,      collision_behavior = .Move_Frogger,  sprite_data = .Short_Log, },
    { rectangle = {0,   7, 1, 1},   speed = -3.5,    row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_1,  },
    { rectangle = {1,   7, 1, 1},   speed = -3.5,    row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_1,  },
    { rectangle = {2,   7, 1, 1},   speed = -3.5,    row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Diving_Turtle_1,  },
    { rectangle = {7,    7, 1, 1},   speed = -3.5,   row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {8,    7, 1, 1},   speed = -3.5,   row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {9,    7, 1, 1},   speed = -3.5,   row_id = 7,      collision_behavior = .Move_Frogger,  sprite_data = Animation_Player_Name.Regular_Turtle, },
    { rectangle = {0,   9, 2, 1},  speed = -1.5,     row_id = 9,      collision_behavior = .Kill_Frogger,  sprite_data = .Truck, },
    { rectangle = {4.5, 9, 2, 1},  speed = -1.5,     row_id = 9,      collision_behavior = .Kill_Frogger,  sprite_data = .Truck, },
    { rectangle = {9, 9, 2, 1},  speed = -1.5,      row_id = 9,      collision_behavior = .Kill_Frogger,  sprite_data = .Truck, },
    { rectangle = {0,  10, 1, 1},  speed = 3  ,      row_id = 10,     collision_behavior = .Kill_Frogger,  sprite_data = .Racecar, },
    { rectangle = {4,  10, 1, 1},  speed = 3  ,    row_id = 10,    collision_behavior = .Kill_Frogger,  sprite_data = .Racecar, },
    { rectangle = {8,  10, 1, 1},  speed = 3  ,    row_id = 10,    collision_behavior = .Kill_Frogger,  sprite_data = .Racecar, },
    { rectangle = {12,  10, 1, 1},  speed = 3  ,    row_id = 10,    collision_behavior = .Kill_Frogger,  sprite_data = .Racecar, },
    { rectangle = {0, 11, 1, 1},     speed = -3  ,   row_id = 11,        collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {3.5,  11, 1, 1},  speed = -3  ,   row_id = 11,     collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {7,  11, 1, 1},  speed = -3  ,   row_id = 11,     collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {10.5,  11, 1, 1},   speed = -3  ,   row_id = 11,      collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },
    { rectangle = {14,  11, 1, 1},   speed = -3  ,   row_id = 11,      collision_behavior = .Kill_Frogger,  sprite_data = .Purple_Car, },

    { rectangle = {0,  12, 1, 1},  speed = 2  ,      row_id = 12,     collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {4,  12, 1, 1},  speed = 2  ,      row_id = 12,     collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {8, 12, 1, 1},  speed = 2  ,       row_id = 12,     collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {12, 12, 1, 1},  speed = 2  ,      row_id = 12,     collision_behavior = .Kill_Frogger,  sprite_data = .Bulldozer, },
    { rectangle = {0, 13, 1, 1},     speed = -1.5  , row_id = 13,     collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
    { rectangle = {5,  13, 1, 1},  speed = -1.5  ,   row_id = 13,     collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
    { rectangle = {10,  13, 1, 1},  speed = -1.5  ,   row_id = 13,     collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
    { rectangle = {15,  13, 1, 1},   speed = -1.5  , row_id = 13,     collision_behavior = .Kill_Frogger,  sprite_data = .Taxi, },
}



otter_spawn_descriptions_level_1 := [?]Spawn_Description {}
otter_spawn_descriptions_level_2 := [?]Spawn_Description {}
otter_spawn_descriptions_level_3 := [?]Spawn_Description {
	{ pos = { -3, 3 },  speed = 2 }, 
	{ pos = { global_number_grid_cells_axis_x, 4 }, speed = -2.5 }, 
	{ pos = { -3, 5 }, speed = 2.5  }, 
	{ pos = { -3, 6 }, speed = 2 }, 
	{ pos = {global_number_grid_cells_axis_x, 7 }, speed = -4 },
}
otter_spawn_descriptions_level_4 := [?]Spawn_Description {
	{ pos = { -3, 3 },  speed = 2.5 }, 
	{ pos = { global_number_grid_cells_axis_x, 4 }, speed = -2.5 }, 
	{ pos = { -3, 5 }, speed = 2.5  }, 
	{ pos = { -3, 6 }, speed = 2 }, 
	{ pos = {global_number_grid_cells_axis_x, 7 }, speed = -4 },
}
otter_spawn_descriptions_level_5 := [?]Spawn_Description {
	{ pos = { -3, 3 },  speed = 2.5 }, 
	{ pos = { global_number_grid_cells_axis_x, 4 }, speed = -2.5 }, 
	{ pos = { -3, 5 }, speed = 2.5  }, 
	{ pos = { -3, 6 }, speed = 2 }, 
	{ pos = {global_number_grid_cells_axis_x, 7 }, speed = -4 },
}

current_otter_spawn_data_id := 0

otter_spawn_descriptions_by_level := [?][]Spawn_Description {
	otter_spawn_descriptions_level_1[:],
	otter_spawn_descriptions_level_2[:],
	otter_spawn_descriptions_level_3[:],
	otter_spawn_descriptions_level_4[:],
	otter_spawn_descriptions_level_5[:],
}


otters_by_level := [?][]Otter {
	otters_level_1[:],
	otters_level_2[:],
	otters_level_3[:],
	otters_level_4[:],
	otters_level_5[:],
}

otters_level_1 := [?]Otter{}
otters_level_2 := [?]Otter{}
otters_level_3 := [?]Otter{ 
	{ entity = { rectangle = {-1, 3, 1, 1}, speed = 2 }, timer_attack = { amount = 2.0, duration = 2.0 } } 
}
otters_level_4 := [?]Otter{ 
	{ entity = { rectangle = {-1, 3, 1, 1}, speed = 2 }, timer_attack = { amount = 2.0, duration = 2.0 } } 
}
otters_level_5 := [?]Otter{ 
	{ entity = { rectangle = {-1, 3, 1, 1}, speed = 2 }, timer_attack = { amount = 2.0, duration = 2.0 } } 
}

snakes_by_level := [?][]Entity {
	snakes_level_1[:],
	snakes_level_2[:],
	snakes_level_3[:],
	snakes_level_4[:],
	snakes_level_5[:],
}

snakes_level_1 := [?]Entity{}
snakes_level_2 := [?]Entity{}
snakes_level_3 := [?]Entity{
	{ rectangle = {-2, 8, 2, 1}, speed = 1, sprite_data = Animation_Player_Name.Snake_0, snake_behavior = { snake_mode = .On_Median, on_entity_id = 12 } },
}
snakes_level_4 := [?]Entity {
	{ rectangle = {-2, 8, 2, 1}, speed = 1.8, sprite_data = Animation_Player_Name.Snake_0, snake_behavior = { snake_mode = .On_Median, on_entity_id = 10 }, },
}
snakes_level_5 := [?]Entity {
	{ rectangle = {-2, 8, 2, 1}, speed = 1, sprite_data = Animation_Player_Name.Snake_0, snake_behavior = { snake_mode = .On_Median, on_entity_id = 8 }, },
	{ rectangle = {global_number_grid_cells_axis_x, 8, 2, 1}, speed = -1, sprite_data = Animation_Player_Name.Snake_1, snake_behavior = { snake_mode = .On_Median, on_entity_id = 9 } },
}
