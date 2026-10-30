locals {
  images = merge({}, [for gallery_key, gallery in var.galleries : {
    for image_key, image in gallery.images : "${gallery_key}/${image_key}" => merge(image, { gallery_key = gallery_key })
  }]...)
  assignments = merge({}, [for schedule_key, schedule in var.patch_schedules : {
    for vm_key, id in schedule.virtual_machines : "${schedule_key}/${vm_key}" => { schedule_key = schedule_key, vm_id = id }
  }]...)
}
