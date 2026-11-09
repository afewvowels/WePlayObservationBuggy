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
  }
})
