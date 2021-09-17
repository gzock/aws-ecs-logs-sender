class EcsEventResult():
  def __init__(self, event):
    self.event = event["detail"]
    self.container_name = self.event["overrides"]["containerOverrides"][0]["name"]
    self.container_cmd = self.event["overrides"]["containerOverrides"][0]["command"][0]
    self.container_fullname = "%s: %s" % (self.container_name, self.container_cmd)
