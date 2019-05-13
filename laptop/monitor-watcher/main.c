/*
 * Compile with -lxcb -lxcb-randr
 */

#include <stdio.h>
#include <stdlib.h>
#include <xcb/xcb.h>
#include <xcb/randr.h>

int main() {
  xcb_connection_t* conn;
  xcb_screen_t* screen;
  xcb_window_t window;
  xcb_generic_event_t* evt;
  xcb_randr_screen_change_notify_event_t* randr_evt;
  xcb_timestamp_t last_time;
  int monitor_connected = 1;

  conn = xcb_connect(NULL, NULL);

  screen = xcb_setup_roots_iterator(xcb_get_setup(conn)).data;
  window = screen->root;
  xcb_randr_select_input(conn, window, XCB_RANDR_NOTIFY_MASK_SCREEN_CHANGE);
  xcb_flush(conn);

  while ((evt = xcb_wait_for_event(conn)) != NULL) {
    if (evt->response_type & XCB_RANDR_NOTIFY_MASK_SCREEN_CHANGE) {
      randr_evt = (xcb_randr_screen_change_notify_event_t*) evt;
      if (last_time != randr_evt->timestamp) {
        last_time = randr_evt->timestamp;
        monitor_connected = !monitor_connected;
        if (monitor_connected) {
          printf("Monitor connected\n");
        } else {
          printf("Monitor disconnected\n");
        }
      }
    }
    free(evt);
  }
  xcb_disconnect(conn);
}
