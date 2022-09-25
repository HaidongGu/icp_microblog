import List "mo:base/List";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Time "mo:base/Time";

actor {
 
  public type Message = {
    message : Text;
    time: Time.Time; // as suggested by https://forum.dfinity.org/t/how-to-convert-time-now-to-yyyy-mm-dd-in-motoko/10407, we don't parse Time value
  };

  public type Microblog = actor {
    follow: shared (Principal) -> async();
    follows: shared query() -> async [Principal];
    post: shared (Text) -> async ();
    posts: shared query (Time.Time) -> async [Message];
    timeline : shared (Time.Time) -> async [Message];
  };

  stable var followed: List.List<Principal> = List.nil();
  stable var messages: List.List<Message> = List.nil();

  public shared func follow (id: Principal): async () {
    followed := List.push(id, followed);
  };

  public shared query func follows(): async [Principal] {
    List.toArray(followed);
  };

  public shared func post (text: Text): async() {
   let post: Message = {
      message = text;
      time = Time.now();
   };
    messages := List.push(post, messages);
  };

  public shared query func posts(since: Time.Time): async [Message] {
    var posts : List.List<Message> = List.nil();

    for (msg in Iter.fromList(messages)) {
      if (msg.time > since ) {
        posts := List.push(msg, posts);
      }
    };

    List.toArray(posts);
  };

  public shared func timeline(since: Time.Time): async [Message] {
    var all : List.List<Message> = List.nil();

    for (id in Iter.fromList(followed)) {
      let canister : Microblog = actor(Principal.toText(id));
      let msgs : [Message] = await canister.posts(since);
      for (msg in Iter.fromArray(msgs)) {
        all := List.push(msg, all);
      };
    };

    List.toArray(all);
  }

};
