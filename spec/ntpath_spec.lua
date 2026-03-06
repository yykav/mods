--[[
  Some test cases were ported from CPython's ntpath tests.
  Adapted and ported to Lua/Busted for this project's API and conventions.
  Source: https://github.com/python/cpython/blob/main/Lib/test/test_ntpath.py
  License: Python Software Foundation License Version 2 (PSF-2.0).
  Copyright (c) 2001 Python Software Foundation; All Rights Reserved.
]]

local lfs = require("lfs")
local mods = require("mods")
local ntpath = mods.ntpath
local fmt = string.format
local tbl_keys = mods.tbl.keys

local function with_env(env, fn)
  stub(os, "getenv", function(name)
    return env[name]
  end)
  fn()
  os.getenv:revert() ---@diagnostic disable-line: undefined-field
end

describe("mods.ntpath", function()
  it("is exposed from mods", function()
    assert.is_table(ntpath)
  end)

  -- stylua: ignore
  local tests = {
    abspath = {
      {{ [[C:\]]                         }, { [[C:\]]                   }},
      {{ [[\\?\C:////spam////eggs. . .]] }, { [[\\?\C:\spam\eggs. . .]] }},
      {{ [[\\.\C:////spam////eggs. . .]] }, { [[\\.\C:\spam\eggs. . .]] }},
      {{ [[//spam//eggs. . .]]           }, { [[\\spam\\eggs. . .]]     }},
      {{ [[\\spam\\eggs. . .]]           }, { [[\\spam\\eggs. . .]]     }},
      {{ [[C:/spam. . .]]                }, { [[C:\spam. . .]]          }},
      {{ [[C:\spam. . .]]                }, { [[C:\spam. . .]]          }},
      {{ [[C:/nul]]                      }, { [[C:\nul]]                }},
      {{ [[C:\nul]]                      }, { [[C:\nul]]                }},
      {{ [[//..]]                        }, { [[\\..]]                  }},
      {{ [[//../]]                       }, { [[\\..\]]                 }},
      {{ [[//../..]]                     }, { [[\\..\..]]               }},
      {{ [[//../../]]                    }, { [[\\..\..\]]              }},
      {{ [[//../../../]]                 }, { [[\\..\..\]]              }},
      {{ [[//../../../..]]               }, { [[\\..\..\]]              }},
      {{ [[//../../../../]]              }, { [[\\..\..\]]              }},
      {{ [[//server]]                    }, { [[\\server]]              }},
      {{ [[//server/]]                   }, { [[\\server\]]             }},
      {{ [[//server/..]]                 }, { [[\\server\..]]           }},
      {{ [[//server/../]]                }, { [[\\server\..\]]          }},
      {{ [[//server/../..]]              }, { [[\\server\..\]]          }},
      {{ [[//server/../../]]             }, { [[\\server\..\]]          }},
      {{ [[//server/../../..]]           }, { [[\\server\..\]]          }},
      {{ [[//server/../../../]]          }, { [[\\server\..\]]          }},
      {{ [[//server/share]]              }, { [[\\server\share]]        }},
      {{ [[//server/share/]]             }, { [[\\server\share\]]       }},
      {{ [[//server/share/..]]           }, { [[\\server\share\]]       }},
      {{ [[//server/share/../]]          }, { [[\\server\share\]]       }},
      {{ [[//server/share/../..]]        }, { [[\\server\share\]]       }},
      {{ [[//server/share/../../]]       }, { [[\\server\share\]]       }},
      {{ [[C:\nul. . .]]                 }, { [[C:\nul. . .]]           }},
      {{ [[//... . .]]                   }, { [[\\... . .]]             }},
      {{ [[//.. . . .]]                  }, { [[\\.. . . .]]            }},
      {{ [[//../... . .]]                }, { [[\\..\... . .]]          }},
      {{ [[//../.. . . .]]               }, { [[\\..\.. . . .]]         }},
      {{ [[C:spam]]                      }, { [[C:spam]]                }},
    },
    basename = {
      {{ [[c:\foo\bar]]                 }, { "bar" }},
      {{ [[\\conky\mountpoint\foo\bar]] }, { "bar" }},
      {{ [[c:\]]                        }, { ""    }},
      {{ [[\\conky\mountpoint\]]        }, { ""    }},
      {{ "c:/"                          }, { ""    }},
      {{ "//conky/mountpoint/"          }, { ""    }},
      {{ "foo/bar"                      }, { "bar" }},
      {{ "foo"                          }, { "foo" }},
      {{ ""                             }, { ""    }},
    },
    commonpath = {
      {{{ [[C:\Foo]]                           }}, { [[C:\Foo]] }},
      {{{ [[C:\Foo]]    , [[C:\Foo]]           }}, { [[C:\Foo]] }},
      {{{ [[C:\Foo\]]   , [[C:\Foo]]           }}, { [[C:\Foo]] }},
      {{{ [[C:\\Foo]]   , [[C:\Foo\\]]         }}, { [[C:\Foo]] }},
      {{{ [[C:\.\Foo]]  , [[C:\Foo\.]]         }}, { [[C:\Foo]] }},
      {{{ [[C:\]]       , [[C:\baz]]           }}, { [[C:\]]    }},
      {{{ [[C:\Bar]]    , [[C:\baz]]           }}, { [[C:\]]    }},
      {{{ [[C:\Foo]]    , [[C:\Foo\Baz]]       }}, { [[C:\Foo]] }},
      {{{ [[C:\Foo\Bar]], [[C:\Foo\Baz]]       }}, { [[C:\Foo]] }},
      {{{ [[C:\Bar]]    , [[C:\Baz]]           }}, { [[C:\]]    }},
      {{{ [[C:\Bar\]]   , [[C:\Baz]]           }}, { [[C:\]]    }},
      {{{ [[C:\Foo\Bar]], "C:/Foo/Baz"         }}, { [[C:\Foo]] }},
      {{{ [[C:\Foo\Bar]], "c:/foo/baz"         }}, { [[C:\Foo]] }},
      {{{ "c:/foo/bar"  , [[C:\Foo\Baz]]       }}, { [[c:\foo]] }},
      {{{ "spam"                               }}, { "spam"     }},
      {{{ "spam"        , "spam"               }}, { "spam"     }},
      {{{ "spam"        , "alot"               }}, { ""         }},
      {{{ [[and\jam]]   , [[and\spam]]         }}, { "and"      }},
      {{{ [[and\\jam]]  , [[and\spam\\]]       }}, { "and"      }},
      {{{ [[and\.\jam]] , [[.\and\spam]]       }}, { "and"      }},
      {{{ [[and\jam]]   , [[and\spam]], "alot" }}, { ""         }},
      {{{ [[and\jam]]   , [[and\spam]], "and"  }}, { "and"      }},
      {{{ [[C:and\jam]] , [[C:and\spam]]       }}, { [[C:and]]  }},
      {{{ ""                                   }}, { ""         }},
      {{{ ""            , [[spam\alot]]        }}, { ""         }},
    },
    dirname = {
      {{ [[c:\foo\bar]]                 }, { [[c:\foo]]                 }},
      {{ [[\\conky\mountpoint\foo\bar]] }, { [[\\conky\mountpoint\foo]] }},
      {{ [[c:\]]                        }, { [[c:\]]                    }},
      {{ [[\\conky\mountpoint\]]        }, { [[\\conky\mountpoint\]]    }},
      {{ "c:/"                          }, { "c:/"                      }},
      {{ "//conky/mountpoint/"          }, { "//conky/mountpoint/"      }},
      {{ "foo/bar"                      }, { "foo"                      }},
      {{ "foo"                          }, { ""                         }},
      {{ ""                             }, { ""                         }},
    },
    expanduser = {
      {{ "test"            }, { "test"            }},
      {{ [[C:\Users\eric]] }, { [[C:\Users\eric]] }},
      {{ "~"               }, { "~"               }},
      {{ [[~\foo\bar]]     }, { [[~\foo\bar]]     }},
      {{ "~test"           }, { "~test"           }},
      {{ [[~test\foo\bar]] }, { [[~test\foo\bar]] }},
    },
    isabs = {
      {{ [[foo\bar]]             }, { false }},
      {{ "foo/bar"               }, { false }},
      {{ [[c:\]]                 }, { true  }},
      {{ [[c:\foo\bar]]          }, { true  }},
      {{ "c:/foo/bar"            }, { true  }},
      {{ [[\\conky\mountpoint\]] }, { true  }},
      {{ [[\foo\bar]]            }, { false }},
      {{ "/foo/bar"              }, { false }},
      {{ [[c:foo\bar]]           }, { false }},
      {{ "c:foo/bar"             }, { false }},
      {{ [[\\conky\mountpoint]]  }, { true  }},
      {{ [[\\.\C:]]              }, { true  }},
    },
    ismount = {
      {{ [[c:\]]             }, { true  }},
      {{ [[C:\]]             }, { true  }},
      {{ [[c:/]]             }, { true  }},
      {{ [[C:/]]             }, { true  }},
      {{ [[\\.\c:\]]         }, { true  }},
      {{ [[\\.\C:\]]         }, { true  }},
      {{ [[\\localhost\c$]]  }, { true  }},
      {{ [[\\localhost\c$\]] }, { true  }},
      {{ "c:"                }, { false }},
      {{ "C:"                }, { false }},
    },
    isreserved = {
      {{ ""               }, { false }},
      {{ "."              }, { false }},
      {{ ".."             }, { false }},
      {{ "/"              }, { false }},
      {{ "/foo/bar"       }, { false }},
      {{ "foo."           }, { true  }},
      {{ "foo "           }, { true  }},
      {{ "foo*bar"        }, { true  }},
      {{ "foo?bar"        }, { true  }},
      {{ 'foo"bar'        }, { true  }},
      {{ "foo<bar"        }, { true  }},
      {{ "foo>bar"        }, { true  }},
      {{ "foo:bar"        }, { true  }},
      {{ "foo|bar"        }, { true  }},
      {{ "nul"            }, { true  }},
      {{ "aux"            }, { true  }},
      {{ "prn"            }, { true  }},
      {{ "con"            }, { true  }},
      {{ "conin$"         }, { true  }},
      {{ "conout$"        }, { true  }},
      {{ "COM1"           }, { true  }},
      {{ "LPT9"           }, { true  }},
      {{ "NUL.txt"        }, { true  }},
      {{ "PRN  "          }, { true  }},
      {{ "AUX  .txt"      }, { true  }},
      {{ "COM1:bar"       }, { true  }},
      {{ "LPT9   :bar"    }, { true  }},
      {{ "bar.com9"       }, { false }},
      {{ "bar.lpt9"       }, { false }},
      {{ "c:/bar/baz/NUL" }, { true  }},
      {{ "c:/NUL/bar/baz" }, { true  }},
      {{ "//./NUL"        }, { false }},
    },
    join = {
      {{ ""                              }, { ""                       }},
      {{ "", "", ""                      }, { ""                       }},
      {{ "a"                             }, { "a"                      }},
      {{ "/a"                            }, { "/a"                     }},
      {{ [[\a]]                          }, { [[\a]]                   }},
      {{ "a:"                            }, { "a:"                     }},
      {{ "a:", [[\b]]                    }, { [[a:\b]]                 }},
      {{ "a", [[\b]]                     }, { [[\b]]                   }},
      {{ "a", "b", "c"                   }, { [[a\b\c]]                }},
      {{ [[a\]], "b", "c"                }, { [[a\b\c]]                }},
      {{ "a", [[b\]], "c"                }, { [[a\b\c]]                }},
      {{ "a", "b", [[c\]]                }, { [[a\b\c\]]               }},
      {{ [[d:\]], [[\pleep]]             }, { [[d:\pleep]]             }},
      {{ [[d:\]], "a", "b"               }, { [[d:\a\b]]               }},
      {{ "a", ""                         }, { [[a\]]                   }},
      {{ "a/", ""                        }, { "a/"                     }},
      {{ "a/b", "x/y"                    }, { [[a/b\x/y]]              }},
      {{ "/a/b", "x/y"                   }, { [[/a/b\x/y]]             }},
      {{ "/a/b/", "x/y"                  }, { "/a/b/x/y"               }},
      {{ "c:", "x/y"                     }, { "c:x/y"                  }},
      {{ "c:a/b", "x/y"                  }, { [[c:a/b\x/y]]            }},
      {{ "c:/", "x/y"                    }, { "c:/x/y"                 }},
      {{ "c:/a/b", "x/y"                 }, { [[c:/a/b\x/y]]           }},
      {{ "//computer/share", "x/y"       }, { [[//computer/share\x/y]] }},
      {{ "a/b", "/x/y"                   }, { "/x/y"                   }},
      {{ "c:", "/x/y"                    }, { "c:/x/y"                 }},
      {{ "c:/a/b", "/x/y"                }, { "c:/x/y"                 }},
      {{ "//computer/share/a", "/x/y"    }, { "//computer/share/x/y"   }},
      {{ "c:", "C:x/y"                   }, { "C:x/y"                  }},
      {{ "c:a/b", "C:x/y"                }, { [[C:a/b\x/y]]            }},
      {{ "c:/", "C:x/y"                  }, { "C:/x/y"                 }},
      {{ [[\\computer\share\]], "a", "b" }, { [[\\computer\share\a\b]] }},
      {{ [[\\computer\share]], [[a\b]]   }, { [[\\computer\share\a\b]] }},
      {{ "a", "Z:b", "c"                 }, { [[Z:b\c]]                }},
      {{ "a", [[Z:\b]], "c"              }, { [[Z:\b\c]]               }},
      {{ "a", [[\\b\c]], "d"             }, { [[\\b\c\d]]              }},
      {{ "a", [[\b]], "c"                }, { [[\b\c]]                 }},
    },
    normcase = {
      {{ ""        }, { ""        }},
      {{ "ABC"     }, { "abc"     }},
      {{ [[A/B\C]] }, { [[a\b\c]] }},
    },
    normpath = {
      {{ "A//////././//.//B"                 }, { [[A\B]]                   }},
      {{ "A/./B"                             }, { [[A\B]]                   }},
      {{ "A/foo/../B"                        }, { [[A\B]]                   }},
      {{ "C:A//B"                            }, { [[C:A\B]]                 }},
      {{ "D:A/./B"                           }, { [[D:A\B]]                 }},
      {{ "e:A/foo/../B"                      }, { [[e:A\B]]                 }},
      {{ "C:///A//B"                         }, { [[C:\A\B]]                }},
      {{ ".."                                }, { ".."                      }},
      {{ "."                                 }, { "."                       }},
      {{ "c:."                               }, { "c:"                      }},
      {{ ""                                  }, { "."                       }},
      {{ "/"                                 }, { [[\]]                     }},
      {{ "c:/"                               }, { [[c:\]]                   }},
      {{ "/../.././.."                       }, { [[\]]                     }},
      {{ "c:/../../.."                       }, { [[c:\]]                   }},
      {{ "/./a/b"                            }, { [[\a\b]]                  }},
      {{ "c:/./a/b"                          }, { [[c:\a\b]]                }},
      {{ "../.././.."                        }, { [[..\..\..]]              }},
      {{ "K:../.././.."                      }, { [[K:..\..\..]]            }},
      {{ "./a/b"                             }, { [[a\b]]                   }},
      {{ "c:./a/b"                           }, { [[c:a\b]]                 }},
      {{ "C:////a/b"                         }, { [[C:\a\b]]                }},
      {{ "//machine/share//a/b"              }, { [[\\machine\share\a\b]]   }},
      {{ [[\\.\NUL]]                         }, { [[\\.\NUL]]               }},
      {{ [[\\?\D:/XY\Z]]                     }, { [[\\?\D:\XY\Z]]           }},
      {{ "handbook/../../Tests/image.png"    }, { [[..\Tests\image.png]]    }},
      {{ "handbook/../../../Tests/image.png" }, { [[..\..\Tests\image.png]] }},
      {{ "handbook///../a/.././../b/c"       }, { [[..\b\c]]                }},
      {{ "handbook/a/../..///../../b/c"      }, { [[..\..\b\c]]             }},
      {{ "//server/share/.."                 }, { [[\\server\share\]]       }},
      {{ "//server/share/../"                }, { [[\\server\share\]]       }},
      {{ "//server/share/../.."              }, { [[\\server\share\]]       }},
      {{ "//server/share/../../"             }, { [[\\server\share\]]       }},
      {{ [[\\foo\\]]                         }, { [[\\foo\\]]               }},
      {{ [[\\foo\]]                          }, { [[\\foo\]]                }},
      {{ [[\\foo]]                           }, { [[\\foo]]                 }},
      {{ [[\\]]                              }, { [[\\]]                    }},
      {{ "//?/UNC/server/share/.."           }, { [[\\?\UNC\server\share\]] }},
    },
    relpath = {
      {{ "a"                                                  }, { "a"                      }},
      {{ "a/b"                                                }, { [[a\b]]                  }},
      {{ "../a/b"                                             }, { [[..\a\b]]               }},
      {{ "a"                     , "a"                        }, { "."                      }},
      {{ [[c:/foo/bar/bat]]      , [[c:/x/y]]                 }, { [[..\..\foo\bar\bat]]    }},
      {{ [[//conky/mountpoint/a]], [[//conky/mountpoint/b/c]] }, { [[..\..\a]]              }},
      {{ "/foo/bar/bat"          , "/x/y/z"                   }, { [[..\..\..\foo\bar\bat]] }},
      {{ "/foo/bar/bat"          , "/foo/bar"                 }, { "bat"                    }},
      {{ "/foo/bar/bat"          , "/"                        }, { [[foo\bar\bat]]          }},
      {{ "/"                     , "/foo/bar/bat"             }, { [[..\..\..]]             }},
      {{ "/"                     , "/"                        }, { "."                      }},
      {{ "/a/b"                  , "/a/b"                     }, { "."                      }},
      {{ "c:/foo"                , "C:/FOO"                   }, { "."                      }},
    },
    split = {
      {{ [[c:\foo\bar]]                   }, { [[c:\foo]]                , "bar" }},
      {{ [[\\conky\mountpoint\foo\bar]]   }, { [[\\conky\mountpoint\foo]], "bar" }},
      {{ [[c:\]]                          }, { [[c:\]]                   , ""    }},
      {{ [[\\conky\mountpoint\]]          }, { [[\\conky\mountpoint\]]   , ""    }},
      {{ "c:/"                            }, { "c:/"                     , ""    }},
      {{ "//conky/mountpoint/"            }, { "//conky/mountpoint/"     , ""    }},
    },
    splitdrive = {
      {{ ""                               }, { ""                      , ""           }},
      {{ "foo"                            }, { ""                      , "foo"        }},
      {{ [[foo\bar]]                      }, { ""                      , [[foo\bar]]  }},
      {{ "foo/bar"                        }, { ""                      , "foo/bar"    }},
      {{ [[\]]                            }, { ""                      , [[\]]        }},
      {{ [[/]]                            }, { ""                      , [[/]]        }},
      {{ [[\foo\bar]]                     }, { ""                      , [[\foo\bar]] }},
      {{ [[/foo/bar]]                     }, { ""                      , [[/foo/bar]] }},
      {{ [[c:foo\bar]]                    }, { "c:"                    , [[foo\bar]]  }},
      {{ "c:foo/bar"                      }, { "c:"                    , "foo/bar"    }},
      {{ [[c:\foo\bar]]                   }, { "c:"                    , [[\foo\bar]] }},
      {{ "c:/foo/bar"                     }, { "c:"                    , "/foo/bar"   }},
      {{ [[\\]]                           }, { [[\\]]                  , ""           }},
      {{ [[//]]                           }, { [[//]]                  , ""           }},
      {{ [[\\conky\mountpoint\foo\bar]]   }, { [[\\conky\mountpoint]]  , [[\foo\bar]] }},
      {{ [[//conky/mountpoint/foo/bar]]   }, { [[//conky/mountpoint]]  , [[/foo/bar]] }},
      {{ [[\\?\UNC\server\share\dir]]     }, { [[\\?\UNC\server\share]], [[\dir]]     }},
      {{ [[//?/UNC/server/share/dir]]     }, { [[//?/UNC/server/share]], [[/dir]]     }},
    },
    splitext = {
      {{ "foo.ext"          }, { "foo"           , ".ext" }},
      {{ "/foo/foo.ext"     }, { "/foo/foo"      , ".ext" }},
      {{ ".ext"             }, { ".ext"          , ""     }},
      {{ [[\foo.ext\foo]]   }, { [[\foo.ext\foo]], ""     }},
      {{ [[foo.ext\]]       }, { [[foo.ext\]]    , ""     }},
      {{ ""                 }, { ""              , ""     }},
      {{ "foo.bar.ext"      }, { "foo.bar"       , ".ext" }},
      {{ "xx/foo.bar.ext"   }, { "xx/foo.bar"    , ".ext" }},
      {{ [[xx\foo.bar.ext]] }, { [[xx\foo.bar]]  , ".ext" }},
      {{ [[c:a/b\c.d]]      }, { [[c:a/b\c]]     , ".d"   }},
    },
    splitroot = {
      {{ ""                                 }, { ""                           , ""   , ""                     }},
      {{ "foo"                              }, { ""                           , ""   , "foo"                  }},
      {{ [[foo\bar]]                        }, { ""                           , ""   , [[foo\bar]]            }},
      {{ "foo/bar"                          }, { ""                           , ""   , "foo/bar"              }},
      {{ [[\]]                              }, { ""                           , [[\]], ""                     }},
      {{ "/"                                }, { ""                           , "/"  , ""                     }},
      {{ [[\foo\bar]]                       }, { ""                           , [[\]], [[foo\bar]]            }},
      {{ "/foo/bar"                         }, { ""                           , "/"  , "foo/bar"              }},
      {{ [[c:foo\bar]]                      }, { "c:"                         , ""   , [[foo\bar]]            }},
      {{ "c:foo/bar"                        }, { "c:"                         , ""   , "foo/bar"              }},
      {{ [[c:\foo\bar]]                     }, { "c:"                         , [[\]], [[foo\bar]]            }},
      {{ "c:/foo/bar"                       }, { "c:"                         , "/"  , "foo/bar"              }},
      {{ [[c:\\a]]                          }, { "c:"                         , [[\]], [[\a]]                 }},
      {{ [[c:\\\a/b]]                       }, { "c:"                         , [[\]], [[\\a/b]]              }},
      {{ [[c:/\]]                           }, { "c:"                         , "/"  , [[\]]                  }},
      {{ [[c:\/]]                           }, { "c:"                         , [[\]], "/"                    }},
      {{ [[/\a/b\/\]]                       }, { [[/\a/b]]                    , [[\]], [[/\]]                 }},
      {{ [[\/a\b/\/]]                       }, { [[\/a\b]]                    , "/"  , [[\/]]                 }},
      {{ [[\\]]                             }, { [[\\]]                       , ""   , ""                     }},
      {{ [[//]]                             }, { [[//]]                       , ""   , ""                     }},
      {{ [[\\conky\mountpoint\foo\bar]]     }, { [[\\conky\mountpoint]]       , [[\]], [[foo\bar]]            }},
      {{ "//conky/mountpoint/foo/bar"       }, { "//conky/mountpoint"         , "/"  , "foo/bar"              }},
      {{ [[\\\conky\mountpoint\foo\bar]]    }, { [[\\\conky]]                 , [[\]], [[mountpoint\foo\bar]] }},
      {{ "///conky/mountpoint/foo/bar"      }, { "///conky"                   , "/"  , "mountpoint/foo/bar"   }},
      {{ [[\\conky\\mountpoint\foo\bar]]    }, { [[\\conky\]]                 , [[\]], [[mountpoint\foo\bar]] }},
      {{ "//conky//mountpoint/foo/bar"      }, { "//conky/"                   , "/"  , "mountpoint/foo/bar"   }},
      {{ "//conky/MOUNTPOİNT/foo/bar"       }, { "//conky/MOUNTPOİNT"         , "/"  , "foo/bar"              }},
      {{ "//?/c:"                           }, { "//?/c:"                     , ""   , ""                     }},
      {{ "//./c:"                           }, { "//./c:"                     , ""   , ""                     }},
      {{ "//?/c:/"                          }, { "//?/c:"                     , "/"  , ""                     }},
      {{ "//?/c:/dir"                       }, { "//?/c:"                     , "/"  , "dir"                  }},
      {{ "//?/UNC"                          }, { "//?/UNC"                    , ""   , ""                     }},
      {{ "//?/UNC/"                         }, { "//?/UNC/"                   , ""   , ""                     }},
      {{ "//?/UNC/server/"                  }, { "//?/UNC/server/"            , ""   , ""                     }},
      {{ "//?/UNC/server/share"             }, { "//?/UNC/server/share"       , ""   , ""                     }},
      {{ "//?/UNC/server/share/dir"         }, { "//?/UNC/server/share"       , "/"  , "dir"                  }},
      {{ "//?/VOLUME{00000000-0000}/spam"   }, { "//?/VOLUME{00000000-0000}"  , "/"  , "spam"                 }},
      {{ "//?/BootPartition/"               }, { "//?/BootPartition"          , "/"  , ""                     }},
      {{ "//./BootPartition/"               }, { "//./BootPartition"          , "/"  , ""                     }},
      {{ "//./PhysicalDrive0"               }, { "//./PhysicalDrive0"         , ""   , ""                     }},
      {{ "//./nul"                          }, { "//./nul"                    , ""   , ""                     }},
      {{ [[\\?\c:]]                         }, { [[\\?\c:]]                   , ""   , ""                     }},
      {{ [[\\.\c:]]                         }, { [[\\.\c:]]                   , ""   , ""                     }},
      {{ [[\\?\c:\]]                        }, { [[\\?\c:]]                   , [[\]], ""                     }},
      {{ [[\\?\c:\dir]]                     }, { [[\\?\c:]]                   , [[\]], "dir"                  }},
      {{ [[\\?\UNC]]                        }, { [[\\?\UNC]]                  , ""   , ""                     }},
      {{ [[\\?\UNC\]]                       }, { [[\\?\UNC\]]                 , ""   , ""                     }},
      {{ [[\\?\UNC\server\]]                }, { [[\\?\UNC\server\]]          , ""   , ""                     }},
      {{ [[\\?\UNC\server\share]]           }, { [[\\?\UNC\server\share]]     , ""   , ""                     }},
      {{ [[\\?\UNC\server\share\dir]]       }, { [[\\?\UNC\server\share]]     , [[\]], "dir"                  }},
      {{ [[\\?\VOLUME{00000000-0000}\spam]] }, { [[\\?\VOLUME{00000000-0000}]], [[\]], "spam"                 }},
      {{ [[\\?\BootPartition\]]             }, { [[\\?\BootPartition]]        , [[\]], ""                     }},
      {{ [[\\.\BootPartition\]]             }, { [[\\.\BootPartition]]        , [[\]], ""                     }},
      {{ [[\\.\PhysicalDrive0]]             }, { [[\\.\PhysicalDrive0]]       , ""   , ""                     }},
      {{ [[\\.\nul]]                        }, { [[\\.\nul]]                  , ""   , ""                     }},
      {{ "//"                               }, { "//"                         , ""   , ""                     }},
      {{ "///"                              }, { "///"                        , ""   , ""                     }},
      {{ "///y"                             }, { "///y"                       , ""   , ""                     }},
      {{ "//x"                              }, { "//x"                        , ""   , ""                     }},
      {{ "//x/"                             }, { "//x/"                       , ""   , ""                     }},
      {{ " :/foo"                           }, { " :"                         , "/"  , "foo"                  }},
      {{ "/:/foo"                           }, { ""                           , "/"  , ":/foo"                }},
    },
  }

  for _, fname in ipairs(tbl_keys(tests)) do
    local cases = tests[fname]
    for i = 1, #cases do
      local params, expected = unpack(cases[i], 1, 2)
      it(fmt("%s(%s)", fname, args_repr(params)), function()
        assert.are_same(expected, { ntpath[fname](unpack(params)) })
      end)
    end
  end

  it("supports abspath with cwd for relative paths", function()
    local expected = ntpath.normpath(ntpath.join(lfs.currentdir(), "a"))
    assert.are_equal(expected, ntpath.abspath("a"))
    assert.are_equal(ntpath.normpath(ntpath.join(lfs.currentdir(), "")), ntpath.abspath(""))
    assert.are_equal(ntpath.normpath(ntpath.join(lfs.currentdir(), " ")), ntpath.abspath(" "))
    assert.are_equal(ntpath.normpath(ntpath.join(lfs.currentdir(), "?")), ntpath.abspath("?"))
  end)

  it("supports abspath for invalid-like path bytes", function()
    assert.are_equal("c:\\fo\0o", ntpath.abspath("c:\\fo\0o"))
    assert.are_equal("c:\\bar", ntpath.abspath("c:\\fo\0o\\..\\bar"))
  end)

  it("returns false for non-root temporary directories", function()
    local root = os.tmpname()
    os.remove(root)
    assert.is_true(lfs.mkdir(root))

    assert.is_false(ntpath.ismount(root))

    lfs.rmdir(root)
  end)

  it("supports isreserved control-character detection", function()
    assert.is_true(ntpath.isreserved(string.char(12) .. "oo"))
  end)

  it("validates relpath input", function()
    assert.has_error(function()
      _ = ntpath.relpath("")
    end, "no path specified")

    assert.has_error(function()
      _ = ntpath.relpath([[C:\a]], [[D:\a]])
    end, "path is on mount 'C:', start on mount 'D:'")
  end)

  it("validates commonpath input", function()
    assert.has_error(ntpath.commonpath, "bad argument #1 (expected table, got no value)")

    assert.has_error(function()
      _ = ntpath.commonpath({})
    end, "commonpath() arg is an empty sequence")

    assert.has_error(function()
      _ = ntpath.commonpath({ [[C:\a]], [[D:\b]] })
    end, "Paths don't have the same drive")

    assert.has_error(function()
      _ = ntpath.commonpath({ [[C:\a]], [[C:b]] })
    end, "Can't mix absolute and relative paths")

    local drive_mismatch_cases = {
      { [[C:\Foo]], [[\Foo]] },
      { [[C:\Foo]], "Foo" },
      { [[C:Foo]], [[\Foo]] },
      { [[C:Foo]], "Foo" },
      { [[C:\Foo]], [[D:\Foo]] },
      { [[C:\Foo]], [[D:Foo]] },
      { [[C:Foo]], [[D:Foo]] },
    }

    for i = 1, #drive_mismatch_cases do
      local paths = drive_mismatch_cases[i]

      assert.has_error(function()
        _ = ntpath.commonpath(paths)
      end, "Paths don't have the same drive")

      assert.has_error(function()
        _ = ntpath.commonpath({ paths[2], paths[1] })
      end, "Paths don't have the same drive")
    end

    local rooted_mismatch_cases = {
      { [[\Foo]], "Foo" },
      { "", [[\spam\alot]] },
    }

    for i = 1, #rooted_mismatch_cases do
      local paths = rooted_mismatch_cases[i]

      assert.has_error(function()
        _ = ntpath.commonpath(paths)
      end, "Can't mix rooted and not-rooted paths")

      assert.has_error(function()
        _ = ntpath.commonpath({ paths[2], paths[1] })
      end, "Can't mix rooted and not-rooted paths")
    end
  end)

  it("supports expanduser home expansion", function()
    assert.are_equal("test", ntpath.expanduser("test"))

    with_env({}, function()
      assert.are_equal("~test", ntpath.expanduser("~test"))
    end)

    with_env({
      HOMEDRIVE = [[C:\]],
      HOMEPATH = [[Users\eric]],
      USERNAME = "eric",
    }, function()
      assert.are_equal([[C:\Users\test]], ntpath.expanduser("~test"))
      assert.are_equal([[C:\Users\eric]], ntpath.expanduser("~"))
    end)

    with_env({
      HOMEPATH = [[Users\eric]],
      USERNAME = "eric",
    }, function()
      assert.are_equal([[Users\test]], ntpath.expanduser("~test"))
      assert.are_equal([[Users\eric]], ntpath.expanduser("~"))
    end)

    with_env({
      USERPROFILE = [[C:\Users\eric]],
      USERNAME = "eric",
    }, function()
      assert.are_equal([[C:\Users\test]], ntpath.expanduser("~test"))
      assert.are_equal([[C:\Users\eric]], ntpath.expanduser("~"))
      assert.are_equal([[C:\Users\test\foo\bar]], ntpath.expanduser([[~test\foo\bar]]))
      assert.are_equal([[C:\Users\test/foo/bar]], ntpath.expanduser("~test/foo/bar"))
      assert.are_equal([[C:\Users\eric\foo\bar]], ntpath.expanduser([[~\foo\bar]]))
      assert.are_equal([[C:\Users\eric/foo/bar]], ntpath.expanduser("~/foo/bar"))
    end)

    with_env({
      HOME = [[F:\]],
      USERPROFILE = [[C:\Users\eric]],
      USERNAME = "eric",
    }, function()
      assert.are_equal([[C:\Users\test]], ntpath.expanduser("~test"))
      assert.are_equal([[C:\Users\eric]], ntpath.expanduser("~"))
    end)

    with_env({
      USERPROFILE = [[C:\Users\eric]],
      USERNAME = "idle",
    }, function()
      assert.are_equal("~test", ntpath.expanduser("~test"))
      assert.are_equal([[C:\Users\eric]], ntpath.expanduser("~"))
    end)
  end)
end)
