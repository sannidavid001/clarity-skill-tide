import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test profile creation and retrieval",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('skill-tide', 'create-profile', 
        [types.ascii("Web Development"), types.uint(10), types.uint(20)],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk();
    
    let profile = chain.callReadOnlyFn(
      'skill-tide',
      'get-profile',
      [types.principal(deployer.address)],
      deployer.address
    );
    
    profile.result.expectSome();
  }
});

Clarinet.test({
  name: "Test offering creation and retrieval",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('skill-tide', 'post-offering',
        [
          types.ascii("JavaScript Tutoring"),
          types.ascii("Teaching JS basics"),
          types.uint(10),
          types.uint(20)
        ],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectUint(1);
    
    let offering = chain.callReadOnlyFn(
      'skill-tide',
      'get-offering',
      [types.uint(1)],
      deployer.address
    );
    
    offering.result.expectSome();
  }
});

Clarinet.test({
  name: "Test meetup scheduling and rating",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // Create offering first
    let block = chain.mineBlock([
      Tx.contractCall('skill-tide', 'post-offering',
        [
          types.ascii("JavaScript Tutoring"),
          types.ascii("Teaching JS basics"),
          types.uint(10),
          types.uint(20)
        ],
        deployer.address
      )
    ]);
    
    // Schedule meetup
    block = chain.mineBlock([
      Tx.contractCall('skill-tide', 'schedule-meetup',
        [
          types.uint(1),
          types.principal(wallet1.address),
          types.uint(1234567890)
        ],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectUint(1);
    
    // Rate meetup
    block = chain.mineBlock([
      Tx.contractCall('skill-tide', 'rate-meetup',
        [types.uint(1), types.uint(5)],
        wallet1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
  }
});
