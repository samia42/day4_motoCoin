import Account "account";

import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Float "mo:base/Float";
import Result "mo:base/Result";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Array "mo:base/Array";
import Subaccount "account";
import Option "mo:base/Option";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import TrieMap "mo:base/TrieMap";
import Nat32 "mo:base/Nat32";

actor motoCoin {
  var ledger = TrieMap.TrieMap<Account, Nat>(Account.accountsEqual, Account.accountsHash);
  type Account = Account.Account;

  // Returns the name of the token
  public query func name() : async Text {
    return "MotoCoin";
  };

  // Returns the symbol of the token
  public query func symbol() : async Text {
    return "MOC";
  };

  // Returns the the total number of tokens on all accounts
  public query func totalSupply() : async Nat {
    return 1_000_000;
  };
  public query func getAllBalances() : async [Nat] {
    Iter.toArray(ledger.vals());
  };

  // Returns the balance of the account
  public query func balanceOf(account : Account) : async Nat {
    let balance : ?Nat = ledger.get(account);
    switch (balance) {
      case (null) 0;
      case (?value) value;
    };
  };

  // Transfer tokens to another account
  public shared ({ caller }) func transfer(from : Account, to : Account, amount : Nat) : async Result.Result<(), Text> {
    if (Account.accountBelongsToPrincipal(from, caller)) {
      var balanceFrom : ?Nat = ledger.get(from);
      var balanceTo : ?Nat = ledger.get(to);
      switch (balanceFrom) {
        case (null) throw Error.reject("Account not exist.");
        case (?value) {
          if (value < amount) throw Error.reject("Not enough Balance") else {
            //quitar amount de from
            switch (ledger.replace(from, (value - amount))) {
              case (null) throw Error.reject("Not an existing key:'from'");
              case (?val) ignore val;
            };
          };
        };
      };
      switch (balanceTo) {
        case (null) { ledger.put(to, amount) };
        case (?value) { ledger.put(to, (value + amount)) };
      };

      #ok;

    } else { #err("its Not your account") };

  };

  // Airdrop 100 MotoCoin to any student that is part of the Bootcamp.
  let studentCanister : actor {
    getAllStudentsPrincipal : shared () -> async [Principal];
  } = actor ("rww3b-zqaaa-aaaam-abioa-cai");

  public shared func airdrop() : async Result.Result<(), Text> {

    try {
      let allStudents : [Principal] = await studentCanister.getAllStudentsPrincipal();

      for (p in allStudents.vals()) {
        let account : Account = {
          owner = p;
          subaccount = null;
        };
        let currentBalance = Option.get(ledger.get(account), 0);
        ledger.put(account, (currentBalance + 100));
      };
      #ok();
    } catch (e) { #err("something went wrong") };
  };
};
