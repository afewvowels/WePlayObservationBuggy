data:extend({
  {
    type = "int-setting",
    name = "wp-observation-buggy-chart-radius",
    setting_type = "runtime-global",
    default_value = 128,
    minimum_value = 32,
    maximum_value = 512,
    order = "a"
  },
  {
    type = "int-setting",
    name = "wp-observation-buggy-chart-interval",
    setting_type = "runtime-global",
    default_value = 60,
    minimum_value = 10,
    maximum_value = 600,
    order = "b"
  },
  {
    type = "int-setting",
    name = "wp-observation-buggy-ping-seconds",
    setting_type = "runtime-per-user",
    default_value = 5,
    minimum_value = 0,
    maximum_value = 60,
    order = "c"
  }
})
