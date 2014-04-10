open Lwt

type t = {
  queue   : Inotify.event Queue.t;
  unix_fd : Unix.file_descr;
  lwt_fd  : Lwt_unix.file_descr;
}

let create () =
  let unix_fd = Inotify.init () in
  { queue   = Queue.create ();
    lwt_fd  = Lwt_unix.of_unix_file_descr unix_fd;
    unix_fd; }

let add_watch inotify path selector =
  Inotify.add_watch inotify.unix_fd path selector

let rm_watch inotify wd =
  Inotify.rm_watch inotify.unix_fd wd

let rec read inotify =
  try
    return (Queue.take inotify.queue)
  with Queue.Empty ->
    Lwt_unix.wait_read inotify.lwt_fd >>= fun () ->
    let events = Inotify.read inotify.unix_fd in
    List.iter (fun event -> Queue.push event inotify.queue) events;
    read inotify

let close inotify =
  Lwt_unix.close inotify.lwt_fd