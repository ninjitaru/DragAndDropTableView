Pod::Spec.new do |s|
  s.name         = "PanableDragAndDropTableView"
  s.version      = "0.1.6"
  s.summary      = "A UITableView where cells can be rearranged by drag and drop. added pan right to activate drag and drop"
  s.homepage     = "https://github.com/ninjitaru/DragAndDropTableView.git"
  s.license      = 'MIT'
  s.author       = { "Erik Johansson" => "erik.gustaf.johansson@gmail.se",
  "Jason Chang" => "ninjitaru@gmail.com" }
  s.source       = { :git => "https://github.com/ninjitaru/DragAndDropTableView.git", :tag => "0.1.6" }
  s.platform     = :ios, '5.0'
  s.source_files = 'DragAndDropTableView'
  s.framework  = 'QuartzCore'
  s.requires_arc = true
end