# Source: https://forum.mikrotik.com/t/ros-tesseract-open-source-routeros-monitoring/183709/2
# Topic: ROS Tesseract (open source RouterOS monitoring)
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

$ > python3 ros-tesseract
Traceback (most recent call last):
  File "/Users/amm0/Documents/ROS-Tesseract/ros-tesseract", line 411, in <module>
    curses.wrapper(main)
    ~~~~~~~~~~~~~~^^^^^^
  File "/usr/local/Cellar/python@3.13/3.13.3/Frameworks/Python.framework/Versions/3.13/lib/python3.13/curses/__init__.py", line 94, in wrapper
    return func(stdscr, *args, **kwds)
  File "/Users/amm0/Documents/ROS-Tesseract/ros-tesseract", line 402, in main
    tPoller = poller(quit, config)
  File "/Users/amm0/Documents/ROS-Tesseract/ros-tesseract", line 153, in __init__
    self.calcHeights()
    ~~~~~~~~~~~~~~~~^^
  File "/Users/amm0/Documents/ROS-Tesseract/ros-tesseract", line 172, in calcHeights
    heights[column].append(len(r[0]) + item.get('padding',0) + 4)
    ~~~~~~~^^^^^^^^
IndexError: list index out of range
