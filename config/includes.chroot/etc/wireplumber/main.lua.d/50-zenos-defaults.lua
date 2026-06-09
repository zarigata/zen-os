-- ZEN-OS WirePlumber Defaults
-- Gaming-optimized audio routing and device defaults

-- Default audio device routing
-- Prefer HDMI/DisplayPort output for gaming setups
rule = {
  matches = {
    {
      { "media.class", "matches", "Audio/Sink" },
      { "api.alsa.card_name", "matches", "*HDMI* *" },
    },
  },
  apply_properties = {
    ["priority.driver"] = 1000,
    ["priority.session"] = 1000,
  },
}

-- Node suspension timeout (0 = never suspend, good for gaming)
-- Prevents audio crackling on wake from suspend
default_endpoint = {
  ["audio/sink"] = 0,
  ["audio/source"] = 0,
}

-- ALSA device properties for gaming
alsa_monitor = {
  rules = {
    {
      matches = {
        {
          { "object.path", "matches", "alsa:*" },
        },
      },
      apply_properties = {
        ["api.alsa.period-size"] = 128,
        ["api.alsa.headroom"] = 512,
        ["api.alsa.disable-batch"] = true,
        ["session.suspend-timeout-seconds"] = 0,
      },
    },
  },
}
