
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller_rom2 is
generic
	(
		ADDR_WIDTH : integer := 15 -- Specify your actual ROM size to save LEs and unnecessary block RAM usage.
	);
port (
	clk : in std_logic;
	reset_n : in std_logic := '1';
	addr : in std_logic_vector(ADDR_WIDTH-1 downto 0);
	q : out std_logic_vector(31 downto 0);
	-- Allow writes - defaults supplied to simplify projects that don't need to write.
	d : in std_logic_vector(31 downto 0) := X"00000000";
	we : in std_logic := '0';
	bytesel : in std_logic_vector(3 downto 0) := "1111"
);
end entity;

architecture rtl of controller_rom2 is

	signal addr1 : integer range 0 to 2**ADDR_WIDTH-1;

	--  build up 2D array to hold the memory
	type word_t is array (0 to 3) of std_logic_vector(7 downto 0);
	type ram_t is array (0 to 2 ** ADDR_WIDTH - 1) of word_t;

	signal ram : ram_t:=
	(

     0 => (x"c2",x"48",x"d4",x"ff"),
     1 => (x"78",x"bf",x"f1",x"f5"),
     2 => (x"bf",x"ed",x"f5",x"c2"),
     3 => (x"ed",x"f5",x"c2",x"49"),
     4 => (x"78",x"a1",x"c1",x"48"),
     5 => (x"a9",x"b7",x"c0",x"c4"),
     6 => (x"ff",x"87",x"e5",x"04"),
     7 => (x"78",x"c8",x"48",x"d0"),
     8 => (x"48",x"f9",x"f5",x"c2"),
     9 => (x"4f",x"26",x"78",x"c0"),
    10 => (x"00",x"00",x"00",x"00"),
    11 => (x"00",x"00",x"00",x"00"),
    12 => (x"5f",x"00",x"00",x"00"),
    13 => (x"00",x"00",x"00",x"5f"),
    14 => (x"00",x"03",x"03",x"00"),
    15 => (x"00",x"00",x"03",x"03"),
    16 => (x"14",x"7f",x"7f",x"14"),
    17 => (x"00",x"14",x"7f",x"7f"),
    18 => (x"6b",x"2e",x"24",x"00"),
    19 => (x"00",x"12",x"3a",x"6b"),
    20 => (x"18",x"36",x"6a",x"4c"),
    21 => (x"00",x"32",x"56",x"6c"),
    22 => (x"59",x"4f",x"7e",x"30"),
    23 => (x"40",x"68",x"3a",x"77"),
    24 => (x"07",x"04",x"00",x"00"),
    25 => (x"00",x"00",x"00",x"03"),
    26 => (x"3e",x"1c",x"00",x"00"),
    27 => (x"00",x"00",x"41",x"63"),
    28 => (x"63",x"41",x"00",x"00"),
    29 => (x"00",x"00",x"1c",x"3e"),
    30 => (x"1c",x"3e",x"2a",x"08"),
    31 => (x"08",x"2a",x"3e",x"1c"),
    32 => (x"3e",x"08",x"08",x"00"),
    33 => (x"00",x"08",x"08",x"3e"),
    34 => (x"e0",x"80",x"00",x"00"),
    35 => (x"00",x"00",x"00",x"60"),
    36 => (x"08",x"08",x"08",x"00"),
    37 => (x"00",x"08",x"08",x"08"),
    38 => (x"60",x"00",x"00",x"00"),
    39 => (x"00",x"00",x"00",x"60"),
    40 => (x"18",x"30",x"60",x"40"),
    41 => (x"01",x"03",x"06",x"0c"),
    42 => (x"59",x"7f",x"3e",x"00"),
    43 => (x"00",x"3e",x"7f",x"4d"),
    44 => (x"7f",x"06",x"04",x"00"),
    45 => (x"00",x"00",x"00",x"7f"),
    46 => (x"71",x"63",x"42",x"00"),
    47 => (x"00",x"46",x"4f",x"59"),
    48 => (x"49",x"63",x"22",x"00"),
    49 => (x"00",x"36",x"7f",x"49"),
    50 => (x"13",x"16",x"1c",x"18"),
    51 => (x"00",x"10",x"7f",x"7f"),
    52 => (x"45",x"67",x"27",x"00"),
    53 => (x"00",x"39",x"7d",x"45"),
    54 => (x"4b",x"7e",x"3c",x"00"),
    55 => (x"00",x"30",x"79",x"49"),
    56 => (x"71",x"01",x"01",x"00"),
    57 => (x"00",x"07",x"0f",x"79"),
    58 => (x"49",x"7f",x"36",x"00"),
    59 => (x"00",x"36",x"7f",x"49"),
    60 => (x"49",x"4f",x"06",x"00"),
    61 => (x"00",x"1e",x"3f",x"69"),
    62 => (x"66",x"00",x"00",x"00"),
    63 => (x"00",x"00",x"00",x"66"),
    64 => (x"e6",x"80",x"00",x"00"),
    65 => (x"00",x"00",x"00",x"66"),
    66 => (x"14",x"08",x"08",x"00"),
    67 => (x"00",x"22",x"22",x"14"),
    68 => (x"14",x"14",x"14",x"00"),
    69 => (x"00",x"14",x"14",x"14"),
    70 => (x"14",x"22",x"22",x"00"),
    71 => (x"00",x"08",x"08",x"14"),
    72 => (x"51",x"03",x"02",x"00"),
    73 => (x"00",x"06",x"0f",x"59"),
    74 => (x"5d",x"41",x"7f",x"3e"),
    75 => (x"00",x"1e",x"1f",x"55"),
    76 => (x"09",x"7f",x"7e",x"00"),
    77 => (x"00",x"7e",x"7f",x"09"),
    78 => (x"49",x"7f",x"7f",x"00"),
    79 => (x"00",x"36",x"7f",x"49"),
    80 => (x"63",x"3e",x"1c",x"00"),
    81 => (x"00",x"41",x"41",x"41"),
    82 => (x"41",x"7f",x"7f",x"00"),
    83 => (x"00",x"1c",x"3e",x"63"),
    84 => (x"49",x"7f",x"7f",x"00"),
    85 => (x"00",x"41",x"41",x"49"),
    86 => (x"09",x"7f",x"7f",x"00"),
    87 => (x"00",x"01",x"01",x"09"),
    88 => (x"41",x"7f",x"3e",x"00"),
    89 => (x"00",x"7a",x"7b",x"49"),
    90 => (x"08",x"7f",x"7f",x"00"),
    91 => (x"00",x"7f",x"7f",x"08"),
    92 => (x"7f",x"41",x"00",x"00"),
    93 => (x"00",x"00",x"41",x"7f"),
    94 => (x"40",x"60",x"20",x"00"),
    95 => (x"00",x"3f",x"7f",x"40"),
    96 => (x"1c",x"08",x"7f",x"7f"),
    97 => (x"00",x"41",x"63",x"36"),
    98 => (x"40",x"7f",x"7f",x"00"),
    99 => (x"00",x"40",x"40",x"40"),
   100 => (x"0c",x"06",x"7f",x"7f"),
   101 => (x"00",x"7f",x"7f",x"06"),
   102 => (x"0c",x"06",x"7f",x"7f"),
   103 => (x"00",x"7f",x"7f",x"18"),
   104 => (x"41",x"7f",x"3e",x"00"),
   105 => (x"00",x"3e",x"7f",x"41"),
   106 => (x"09",x"7f",x"7f",x"00"),
   107 => (x"00",x"06",x"0f",x"09"),
   108 => (x"61",x"41",x"7f",x"3e"),
   109 => (x"00",x"40",x"7e",x"7f"),
   110 => (x"09",x"7f",x"7f",x"00"),
   111 => (x"00",x"66",x"7f",x"19"),
   112 => (x"4d",x"6f",x"26",x"00"),
   113 => (x"00",x"32",x"7b",x"59"),
   114 => (x"7f",x"01",x"01",x"00"),
   115 => (x"00",x"01",x"01",x"7f"),
   116 => (x"40",x"7f",x"3f",x"00"),
   117 => (x"00",x"3f",x"7f",x"40"),
   118 => (x"70",x"3f",x"0f",x"00"),
   119 => (x"00",x"0f",x"3f",x"70"),
   120 => (x"18",x"30",x"7f",x"7f"),
   121 => (x"00",x"7f",x"7f",x"30"),
   122 => (x"1c",x"36",x"63",x"41"),
   123 => (x"41",x"63",x"36",x"1c"),
   124 => (x"7c",x"06",x"03",x"01"),
   125 => (x"01",x"03",x"06",x"7c"),
   126 => (x"4d",x"59",x"71",x"61"),
   127 => (x"00",x"41",x"43",x"47"),
   128 => (x"7f",x"7f",x"00",x"00"),
   129 => (x"00",x"00",x"41",x"41"),
   130 => (x"0c",x"06",x"03",x"01"),
   131 => (x"40",x"60",x"30",x"18"),
   132 => (x"41",x"41",x"00",x"00"),
   133 => (x"00",x"00",x"7f",x"7f"),
   134 => (x"03",x"06",x"0c",x"08"),
   135 => (x"00",x"08",x"0c",x"06"),
   136 => (x"80",x"80",x"80",x"80"),
   137 => (x"00",x"80",x"80",x"80"),
   138 => (x"03",x"00",x"00",x"00"),
   139 => (x"00",x"00",x"04",x"07"),
   140 => (x"54",x"74",x"20",x"00"),
   141 => (x"00",x"78",x"7c",x"54"),
   142 => (x"44",x"7f",x"7f",x"00"),
   143 => (x"00",x"38",x"7c",x"44"),
   144 => (x"44",x"7c",x"38",x"00"),
   145 => (x"00",x"00",x"44",x"44"),
   146 => (x"44",x"7c",x"38",x"00"),
   147 => (x"00",x"7f",x"7f",x"44"),
   148 => (x"54",x"7c",x"38",x"00"),
   149 => (x"00",x"18",x"5c",x"54"),
   150 => (x"7f",x"7e",x"04",x"00"),
   151 => (x"00",x"00",x"05",x"05"),
   152 => (x"a4",x"bc",x"18",x"00"),
   153 => (x"00",x"7c",x"fc",x"a4"),
   154 => (x"04",x"7f",x"7f",x"00"),
   155 => (x"00",x"78",x"7c",x"04"),
   156 => (x"3d",x"00",x"00",x"00"),
   157 => (x"00",x"00",x"40",x"7d"),
   158 => (x"80",x"80",x"80",x"00"),
   159 => (x"00",x"00",x"7d",x"fd"),
   160 => (x"10",x"7f",x"7f",x"00"),
   161 => (x"00",x"44",x"6c",x"38"),
   162 => (x"3f",x"00",x"00",x"00"),
   163 => (x"00",x"00",x"40",x"7f"),
   164 => (x"18",x"0c",x"7c",x"7c"),
   165 => (x"00",x"78",x"7c",x"0c"),
   166 => (x"04",x"7c",x"7c",x"00"),
   167 => (x"00",x"78",x"7c",x"04"),
   168 => (x"44",x"7c",x"38",x"00"),
   169 => (x"00",x"38",x"7c",x"44"),
   170 => (x"24",x"fc",x"fc",x"00"),
   171 => (x"00",x"18",x"3c",x"24"),
   172 => (x"24",x"3c",x"18",x"00"),
   173 => (x"00",x"fc",x"fc",x"24"),
   174 => (x"04",x"7c",x"7c",x"00"),
   175 => (x"00",x"08",x"0c",x"04"),
   176 => (x"54",x"5c",x"48",x"00"),
   177 => (x"00",x"20",x"74",x"54"),
   178 => (x"7f",x"3f",x"04",x"00"),
   179 => (x"00",x"00",x"44",x"44"),
   180 => (x"40",x"7c",x"3c",x"00"),
   181 => (x"00",x"7c",x"7c",x"40"),
   182 => (x"60",x"3c",x"1c",x"00"),
   183 => (x"00",x"1c",x"3c",x"60"),
   184 => (x"30",x"60",x"7c",x"3c"),
   185 => (x"00",x"3c",x"7c",x"60"),
   186 => (x"10",x"38",x"6c",x"44"),
   187 => (x"00",x"44",x"6c",x"38"),
   188 => (x"e0",x"bc",x"1c",x"00"),
   189 => (x"00",x"1c",x"3c",x"60"),
   190 => (x"74",x"64",x"44",x"00"),
   191 => (x"00",x"44",x"4c",x"5c"),
   192 => (x"3e",x"08",x"08",x"00"),
   193 => (x"00",x"41",x"41",x"77"),
   194 => (x"7f",x"00",x"00",x"00"),
   195 => (x"00",x"00",x"00",x"7f"),
   196 => (x"77",x"41",x"41",x"00"),
   197 => (x"00",x"08",x"08",x"3e"),
   198 => (x"03",x"01",x"01",x"02"),
   199 => (x"00",x"01",x"02",x"02"),
   200 => (x"7f",x"7f",x"7f",x"7f"),
   201 => (x"00",x"7f",x"7f",x"7f"),
   202 => (x"1c",x"1c",x"08",x"08"),
   203 => (x"7f",x"7f",x"3e",x"3e"),
   204 => (x"3e",x"3e",x"7f",x"7f"),
   205 => (x"08",x"08",x"1c",x"1c"),
   206 => (x"7c",x"18",x"10",x"00"),
   207 => (x"00",x"10",x"18",x"7c"),
   208 => (x"7c",x"30",x"10",x"00"),
   209 => (x"00",x"10",x"30",x"7c"),
   210 => (x"60",x"60",x"30",x"10"),
   211 => (x"00",x"06",x"1e",x"78"),
   212 => (x"18",x"3c",x"66",x"42"),
   213 => (x"00",x"42",x"66",x"3c"),
   214 => (x"c2",x"6a",x"38",x"78"),
   215 => (x"00",x"38",x"6c",x"c6"),
   216 => (x"60",x"00",x"00",x"60"),
   217 => (x"00",x"60",x"00",x"00"),
   218 => (x"5c",x"5b",x"5e",x"0e"),
   219 => (x"71",x"1e",x"0e",x"5d"),
   220 => (x"ca",x"f6",x"c2",x"4c"),
   221 => (x"4b",x"c0",x"4d",x"bf"),
   222 => (x"ab",x"74",x"1e",x"c0"),
   223 => (x"c4",x"87",x"c7",x"02"),
   224 => (x"78",x"c0",x"48",x"a6"),
   225 => (x"a6",x"c4",x"87",x"c5"),
   226 => (x"c4",x"78",x"c1",x"48"),
   227 => (x"49",x"73",x"1e",x"66"),
   228 => (x"c8",x"87",x"df",x"ee"),
   229 => (x"49",x"e0",x"c0",x"86"),
   230 => (x"c4",x"87",x"ef",x"ef"),
   231 => (x"49",x"6a",x"4a",x"a5"),
   232 => (x"f1",x"87",x"f0",x"f0"),
   233 => (x"85",x"cb",x"87",x"c6"),
   234 => (x"b7",x"c8",x"83",x"c1"),
   235 => (x"c7",x"ff",x"04",x"ab"),
   236 => (x"4d",x"26",x"26",x"87"),
   237 => (x"4b",x"26",x"4c",x"26"),
   238 => (x"71",x"1e",x"4f",x"26"),
   239 => (x"ce",x"f6",x"c2",x"4a"),
   240 => (x"ce",x"f6",x"c2",x"5a"),
   241 => (x"49",x"78",x"c7",x"48"),
   242 => (x"26",x"87",x"dd",x"fe"),
   243 => (x"1e",x"73",x"1e",x"4f"),
   244 => (x"b7",x"c0",x"4a",x"71"),
   245 => (x"87",x"d3",x"03",x"aa"),
   246 => (x"bf",x"ed",x"dc",x"c2"),
   247 => (x"c1",x"87",x"c4",x"05"),
   248 => (x"c0",x"87",x"c2",x"4b"),
   249 => (x"f1",x"dc",x"c2",x"4b"),
   250 => (x"c2",x"87",x"c4",x"5b"),
   251 => (x"c2",x"5a",x"f1",x"dc"),
   252 => (x"4a",x"bf",x"ed",x"dc"),
   253 => (x"c0",x"c1",x"9a",x"c1"),
   254 => (x"e8",x"ec",x"49",x"a2"),
   255 => (x"c2",x"48",x"fc",x"87"),
   256 => (x"78",x"bf",x"ed",x"dc"),
   257 => (x"1e",x"87",x"ef",x"fe"),
   258 => (x"66",x"c4",x"4a",x"71"),
   259 => (x"ff",x"49",x"72",x"1e"),
   260 => (x"26",x"87",x"da",x"df"),
   261 => (x"c2",x"1e",x"4f",x"26"),
   262 => (x"49",x"bf",x"ed",x"dc"),
   263 => (x"87",x"c2",x"dc",x"ff"),
   264 => (x"48",x"c2",x"f6",x"c2"),
   265 => (x"c2",x"78",x"bf",x"e8"),
   266 => (x"ec",x"48",x"fe",x"f5"),
   267 => (x"f6",x"c2",x"78",x"bf"),
   268 => (x"49",x"4a",x"bf",x"c2"),
   269 => (x"c8",x"99",x"ff",x"c3"),
   270 => (x"48",x"72",x"2a",x"b7"),
   271 => (x"f6",x"c2",x"b0",x"71"),
   272 => (x"4f",x"26",x"58",x"ca"),
   273 => (x"5c",x"5b",x"5e",x"0e"),
   274 => (x"4b",x"71",x"0e",x"5d"),
   275 => (x"c2",x"87",x"c7",x"ff"),
   276 => (x"c0",x"48",x"fd",x"f5"),
   277 => (x"ff",x"49",x"73",x"50"),
   278 => (x"70",x"87",x"e7",x"db"),
   279 => (x"9c",x"c2",x"4c",x"49"),
   280 => (x"cb",x"49",x"ee",x"cb"),
   281 => (x"49",x"70",x"87",x"cf"),
   282 => (x"fd",x"f5",x"c2",x"4d"),
   283 => (x"c1",x"05",x"bf",x"97"),
   284 => (x"66",x"d0",x"87",x"e4"),
   285 => (x"c6",x"f6",x"c2",x"49"),
   286 => (x"d7",x"05",x"99",x"bf"),
   287 => (x"49",x"66",x"d4",x"87"),
   288 => (x"bf",x"fe",x"f5",x"c2"),
   289 => (x"87",x"cc",x"05",x"99"),
   290 => (x"da",x"ff",x"49",x"73"),
   291 => (x"98",x"70",x"87",x"f4"),
   292 => (x"87",x"c2",x"c1",x"02"),
   293 => (x"fd",x"fd",x"4c",x"c1"),
   294 => (x"ca",x"49",x"75",x"87"),
   295 => (x"98",x"70",x"87",x"e3"),
   296 => (x"c2",x"87",x"c6",x"02"),
   297 => (x"c1",x"48",x"fd",x"f5"),
   298 => (x"fd",x"f5",x"c2",x"50"),
   299 => (x"c0",x"05",x"bf",x"97"),
   300 => (x"f6",x"c2",x"87",x"e4"),
   301 => (x"d0",x"49",x"bf",x"c6"),
   302 => (x"ff",x"05",x"99",x"66"),
   303 => (x"f5",x"c2",x"87",x"d6"),
   304 => (x"d4",x"49",x"bf",x"fe"),
   305 => (x"ff",x"05",x"99",x"66"),
   306 => (x"49",x"73",x"87",x"ca"),
   307 => (x"87",x"f2",x"d9",x"ff"),
   308 => (x"fe",x"05",x"98",x"70"),
   309 => (x"48",x"74",x"87",x"fe"),
   310 => (x"0e",x"87",x"d7",x"fb"),
   311 => (x"5d",x"5c",x"5b",x"5e"),
   312 => (x"c0",x"86",x"f4",x"0e"),
   313 => (x"bf",x"ec",x"4c",x"4d"),
   314 => (x"48",x"a6",x"c4",x"7e"),
   315 => (x"bf",x"ca",x"f6",x"c2"),
   316 => (x"c0",x"1e",x"c1",x"78"),
   317 => (x"fd",x"49",x"c7",x"1e"),
   318 => (x"86",x"c8",x"87",x"ca"),
   319 => (x"ce",x"02",x"98",x"70"),
   320 => (x"fb",x"49",x"ff",x"87"),
   321 => (x"da",x"c1",x"87",x"c7"),
   322 => (x"f5",x"d8",x"ff",x"49"),
   323 => (x"c2",x"4d",x"c1",x"87"),
   324 => (x"bf",x"97",x"fd",x"f5"),
   325 => (x"cd",x"87",x"c3",x"02"),
   326 => (x"f6",x"c2",x"87",x"f9"),
   327 => (x"c2",x"4b",x"bf",x"c2"),
   328 => (x"05",x"bf",x"ed",x"dc"),
   329 => (x"c3",x"87",x"eb",x"c0"),
   330 => (x"d8",x"ff",x"49",x"fd"),
   331 => (x"fa",x"c3",x"87",x"d4"),
   332 => (x"cd",x"d8",x"ff",x"49"),
   333 => (x"c3",x"49",x"73",x"87"),
   334 => (x"1e",x"71",x"99",x"ff"),
   335 => (x"c6",x"fb",x"49",x"c0"),
   336 => (x"c8",x"49",x"73",x"87"),
   337 => (x"1e",x"71",x"29",x"b7"),
   338 => (x"fa",x"fa",x"49",x"c1"),
   339 => (x"c6",x"86",x"c8",x"87"),
   340 => (x"f6",x"c2",x"87",x"c1"),
   341 => (x"9b",x"4b",x"bf",x"c6"),
   342 => (x"c2",x"87",x"dd",x"02"),
   343 => (x"49",x"bf",x"e9",x"dc"),
   344 => (x"70",x"87",x"de",x"c7"),
   345 => (x"87",x"c4",x"05",x"98"),
   346 => (x"87",x"d2",x"4b",x"c0"),
   347 => (x"c7",x"49",x"e0",x"c2"),
   348 => (x"dc",x"c2",x"87",x"c3"),
   349 => (x"87",x"c6",x"58",x"ed"),
   350 => (x"48",x"e9",x"dc",x"c2"),
   351 => (x"49",x"73",x"78",x"c0"),
   352 => (x"ce",x"05",x"99",x"c2"),
   353 => (x"49",x"eb",x"c3",x"87"),
   354 => (x"87",x"f6",x"d6",x"ff"),
   355 => (x"99",x"c2",x"49",x"70"),
   356 => (x"fb",x"87",x"c2",x"02"),
   357 => (x"c1",x"49",x"73",x"4c"),
   358 => (x"87",x"ce",x"05",x"99"),
   359 => (x"ff",x"49",x"f4",x"c3"),
   360 => (x"70",x"87",x"df",x"d6"),
   361 => (x"02",x"99",x"c2",x"49"),
   362 => (x"4c",x"fa",x"87",x"c2"),
   363 => (x"99",x"c8",x"49",x"73"),
   364 => (x"c3",x"87",x"ce",x"05"),
   365 => (x"d6",x"ff",x"49",x"f5"),
   366 => (x"49",x"70",x"87",x"c8"),
   367 => (x"d5",x"02",x"99",x"c2"),
   368 => (x"ce",x"f6",x"c2",x"87"),
   369 => (x"87",x"ca",x"02",x"bf"),
   370 => (x"c2",x"88",x"c1",x"48"),
   371 => (x"c0",x"58",x"d2",x"f6"),
   372 => (x"4c",x"ff",x"87",x"c2"),
   373 => (x"49",x"73",x"4d",x"c1"),
   374 => (x"ce",x"05",x"99",x"c4"),
   375 => (x"49",x"f2",x"c3",x"87"),
   376 => (x"87",x"de",x"d5",x"ff"),
   377 => (x"99",x"c2",x"49",x"70"),
   378 => (x"c2",x"87",x"dc",x"02"),
   379 => (x"7e",x"bf",x"ce",x"f6"),
   380 => (x"a8",x"b7",x"c7",x"48"),
   381 => (x"87",x"cb",x"c0",x"03"),
   382 => (x"80",x"c1",x"48",x"6e"),
   383 => (x"58",x"d2",x"f6",x"c2"),
   384 => (x"fe",x"87",x"c2",x"c0"),
   385 => (x"c3",x"4d",x"c1",x"4c"),
   386 => (x"d4",x"ff",x"49",x"fd"),
   387 => (x"49",x"70",x"87",x"f4"),
   388 => (x"c0",x"02",x"99",x"c2"),
   389 => (x"f6",x"c2",x"87",x"d5"),
   390 => (x"c0",x"02",x"bf",x"ce"),
   391 => (x"f6",x"c2",x"87",x"c9"),
   392 => (x"78",x"c0",x"48",x"ce"),
   393 => (x"fd",x"87",x"c2",x"c0"),
   394 => (x"c3",x"4d",x"c1",x"4c"),
   395 => (x"d4",x"ff",x"49",x"fa"),
   396 => (x"49",x"70",x"87",x"d0"),
   397 => (x"c0",x"02",x"99",x"c2"),
   398 => (x"f6",x"c2",x"87",x"d9"),
   399 => (x"c7",x"48",x"bf",x"ce"),
   400 => (x"c0",x"03",x"a8",x"b7"),
   401 => (x"f6",x"c2",x"87",x"c9"),
   402 => (x"78",x"c7",x"48",x"ce"),
   403 => (x"fc",x"87",x"c2",x"c0"),
   404 => (x"c0",x"4d",x"c1",x"4c"),
   405 => (x"c0",x"03",x"ac",x"b7"),
   406 => (x"66",x"c4",x"87",x"d1"),
   407 => (x"82",x"d8",x"c1",x"4a"),
   408 => (x"c6",x"c0",x"02",x"6a"),
   409 => (x"74",x"4b",x"6a",x"87"),
   410 => (x"c0",x"0f",x"73",x"49"),
   411 => (x"1e",x"f0",x"c3",x"1e"),
   412 => (x"f7",x"49",x"da",x"c1"),
   413 => (x"86",x"c8",x"87",x"ce"),
   414 => (x"c0",x"02",x"98",x"70"),
   415 => (x"a6",x"c8",x"87",x"e2"),
   416 => (x"ce",x"f6",x"c2",x"48"),
   417 => (x"66",x"c8",x"78",x"bf"),
   418 => (x"c4",x"91",x"cb",x"49"),
   419 => (x"80",x"71",x"48",x"66"),
   420 => (x"bf",x"6e",x"7e",x"70"),
   421 => (x"87",x"c8",x"c0",x"02"),
   422 => (x"c8",x"4b",x"bf",x"6e"),
   423 => (x"0f",x"73",x"49",x"66"),
   424 => (x"c0",x"02",x"9d",x"75"),
   425 => (x"f6",x"c2",x"87",x"c8"),
   426 => (x"f2",x"49",x"bf",x"ce"),
   427 => (x"dc",x"c2",x"87",x"fa"),
   428 => (x"c0",x"02",x"bf",x"f1"),
   429 => (x"c2",x"49",x"87",x"dd"),
   430 => (x"98",x"70",x"87",x"c7"),
   431 => (x"87",x"d3",x"c0",x"02"),
   432 => (x"bf",x"ce",x"f6",x"c2"),
   433 => (x"87",x"e0",x"f2",x"49"),
   434 => (x"c0",x"f4",x"49",x"c0"),
   435 => (x"f1",x"dc",x"c2",x"87"),
   436 => (x"f4",x"78",x"c0",x"48"),
   437 => (x"87",x"da",x"f3",x"8e"),
   438 => (x"5c",x"5b",x"5e",x"0e"),
   439 => (x"71",x"1e",x"0e",x"5d"),
   440 => (x"ca",x"f6",x"c2",x"4c"),
   441 => (x"cd",x"c1",x"49",x"bf"),
   442 => (x"d1",x"c1",x"4d",x"a1"),
   443 => (x"74",x"7e",x"69",x"81"),
   444 => (x"87",x"cf",x"02",x"9c"),
   445 => (x"74",x"4b",x"a5",x"c4"),
   446 => (x"ca",x"f6",x"c2",x"7b"),
   447 => (x"f9",x"f2",x"49",x"bf"),
   448 => (x"74",x"7b",x"6e",x"87"),
   449 => (x"87",x"c4",x"05",x"9c"),
   450 => (x"87",x"c2",x"4b",x"c0"),
   451 => (x"49",x"73",x"4b",x"c1"),
   452 => (x"d4",x"87",x"fa",x"f2"),
   453 => (x"87",x"c7",x"02",x"66"),
   454 => (x"70",x"87",x"da",x"49"),
   455 => (x"c0",x"87",x"c2",x"4a"),
   456 => (x"f5",x"dc",x"c2",x"4a"),
   457 => (x"c9",x"f2",x"26",x"5a"),
   458 => (x"00",x"00",x"00",x"87"),
   459 => (x"00",x"00",x"00",x"00"),
   460 => (x"00",x"00",x"00",x"00"),
   461 => (x"4a",x"71",x"1e",x"00"),
   462 => (x"49",x"bf",x"c8",x"ff"),
   463 => (x"26",x"48",x"a1",x"72"),
   464 => (x"c8",x"ff",x"1e",x"4f"),
   465 => (x"c0",x"fe",x"89",x"bf"),
   466 => (x"c0",x"c0",x"c0",x"c0"),
   467 => (x"87",x"c4",x"01",x"a9"),
   468 => (x"87",x"c2",x"4a",x"c0"),
   469 => (x"48",x"72",x"4a",x"c1"),
   470 => (x"5e",x"0e",x"4f",x"26"),
   471 => (x"0e",x"5d",x"5c",x"5b"),
   472 => (x"ff",x"4d",x"71",x"1e"),
   473 => (x"1e",x"75",x"4b",x"d4"),
   474 => (x"49",x"d2",x"f6",x"c2"),
   475 => (x"87",x"f2",x"c1",x"fe"),
   476 => (x"7e",x"70",x"86",x"c4"),
   477 => (x"ff",x"c3",x"02",x"6e"),
   478 => (x"da",x"f6",x"c2",x"87"),
   479 => (x"49",x"75",x"4c",x"bf"),
   480 => (x"87",x"e0",x"db",x"fe"),
   481 => (x"c0",x"05",x"a8",x"de"),
   482 => (x"49",x"75",x"87",x"eb"),
   483 => (x"87",x"ec",x"d3",x"ff"),
   484 => (x"db",x"02",x"98",x"70"),
   485 => (x"d5",x"f5",x"c2",x"87"),
   486 => (x"e1",x"c0",x"1e",x"bf"),
   487 => (x"f7",x"d0",x"ff",x"49"),
   488 => (x"c2",x"86",x"c4",x"87"),
   489 => (x"c0",x"48",x"d2",x"e2"),
   490 => (x"e1",x"f5",x"c2",x"50"),
   491 => (x"87",x"ea",x"fe",x"49"),
   492 => (x"c5",x"c3",x"48",x"c1"),
   493 => (x"48",x"d0",x"ff",x"87"),
   494 => (x"c1",x"78",x"c5",x"c8"),
   495 => (x"4a",x"c0",x"7b",x"d6"),
   496 => (x"7b",x"bf",x"97",x"6e"),
   497 => (x"80",x"c1",x"48",x"6e"),
   498 => (x"82",x"c1",x"7e",x"70"),
   499 => (x"aa",x"b7",x"e0",x"c0"),
   500 => (x"87",x"ec",x"ff",x"04"),
   501 => (x"c4",x"48",x"d0",x"ff"),
   502 => (x"78",x"c5",x"c8",x"78"),
   503 => (x"c1",x"7b",x"d3",x"c1"),
   504 => (x"74",x"78",x"c4",x"7b"),
   505 => (x"fd",x"c1",x"02",x"9c"),
   506 => (x"ce",x"e4",x"c2",x"87"),
   507 => (x"4d",x"c0",x"c8",x"7e"),
   508 => (x"ac",x"b7",x"c0",x"8c"),
   509 => (x"c8",x"87",x"c6",x"03"),
   510 => (x"c0",x"4d",x"a4",x"c0"),
   511 => (x"ff",x"f0",x"c2",x"4c"),
   512 => (x"d0",x"49",x"bf",x"97"),
   513 => (x"87",x"d2",x"02",x"99"),
   514 => (x"f6",x"c2",x"1e",x"c0"),
   515 => (x"c2",x"fe",x"49",x"d2"),
   516 => (x"86",x"c4",x"87",x"ec"),
   517 => (x"c0",x"4a",x"49",x"70"),
   518 => (x"e4",x"c2",x"87",x"ef"),
   519 => (x"f6",x"c2",x"1e",x"ce"),
   520 => (x"c2",x"fe",x"49",x"d2"),
   521 => (x"86",x"c4",x"87",x"d8"),
   522 => (x"ff",x"4a",x"49",x"70"),
   523 => (x"c5",x"c8",x"48",x"d0"),
   524 => (x"7b",x"d4",x"c1",x"78"),
   525 => (x"7b",x"bf",x"97",x"6e"),
   526 => (x"80",x"c1",x"48",x"6e"),
   527 => (x"8d",x"c1",x"7e",x"70"),
   528 => (x"87",x"f0",x"ff",x"05"),
   529 => (x"c4",x"48",x"d0",x"ff"),
   530 => (x"05",x"9a",x"72",x"78"),
   531 => (x"c0",x"87",x"c5",x"c0"),
   532 => (x"87",x"e6",x"c0",x"48"),
   533 => (x"f6",x"c2",x"1e",x"c1"),
   534 => (x"ff",x"fd",x"49",x"d2"),
   535 => (x"86",x"c4",x"87",x"ff"),
   536 => (x"fe",x"05",x"9c",x"74"),
   537 => (x"d0",x"ff",x"87",x"c3"),
   538 => (x"78",x"c5",x"c8",x"48"),
   539 => (x"c0",x"7b",x"d3",x"c1"),
   540 => (x"c1",x"78",x"c4",x"7b"),
   541 => (x"87",x"c2",x"c0",x"48"),
   542 => (x"26",x"26",x"48",x"c0"),
   543 => (x"26",x"4c",x"26",x"4d"),
   544 => (x"1e",x"4f",x"26",x"4b"),
   545 => (x"66",x"c4",x"4a",x"71"),
   546 => (x"72",x"87",x"c5",x"05"),
   547 => (x"87",x"ca",x"fb",x"49"),
   548 => (x"1e",x"00",x"4f",x"26"),
   549 => (x"bf",x"e1",x"e3",x"c2"),
   550 => (x"c2",x"b9",x"c1",x"49"),
   551 => (x"ff",x"59",x"e5",x"e3"),
   552 => (x"ff",x"c3",x"48",x"d4"),
   553 => (x"48",x"d0",x"ff",x"78"),
   554 => (x"ff",x"78",x"e1",x"c8"),
   555 => (x"78",x"c1",x"48",x"d4"),
   556 => (x"78",x"71",x"31",x"c4"),
   557 => (x"c0",x"48",x"d0",x"ff"),
   558 => (x"4f",x"26",x"78",x"e0"),
   559 => (x"d5",x"e3",x"c2",x"1e"),
   560 => (x"d2",x"f6",x"c2",x"1e"),
   561 => (x"d9",x"fc",x"fd",x"49"),
   562 => (x"70",x"86",x"c4",x"87"),
   563 => (x"87",x"c3",x"02",x"98"),
   564 => (x"26",x"87",x"c0",x"ff"),
   565 => (x"4b",x"35",x"31",x"4f"),
   566 => (x"20",x"20",x"5a",x"48"),
   567 => (x"47",x"46",x"43",x"20"),
   568 => (x"00",x"00",x"00",x"00"),
   569 => (x"00",x"00",x"00",x"00"),
		others => (others => x"00")
	);
	signal q1_local : word_t;

	-- Altera Quartus attributes
	attribute ramstyle: string;
	attribute ramstyle of ram: signal is "no_rw_check";

begin  -- rtl

	addr1 <= to_integer(unsigned(addr(ADDR_WIDTH-1 downto 0)));

	-- Reorganize the read data from the RAM to match the output
	q(7 downto 0) <= q1_local(3);
	q(15 downto 8) <= q1_local(2);
	q(23 downto 16) <= q1_local(1);
	q(31 downto 24) <= q1_local(0);

	process(clk)
	begin
		if(rising_edge(clk)) then 
			if(we = '1') then
				-- edit this code if using other than four bytes per word
				if (bytesel(3) = '1') then
					ram(addr1)(3) <= d(7 downto 0);
				end if;
				if (bytesel(2) = '1') then
					ram(addr1)(2) <= d(15 downto 8);
				end if;
				if (bytesel(1) = '1') then
					ram(addr1)(1) <= d(23 downto 16);
				end if;
				if (bytesel(0) = '1') then
					ram(addr1)(0) <= d(31 downto 24);
				end if;
			end if;
			q1_local <= ram(addr1);
		end if;
	end process;
  
end rtl;
