import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test profile creation, update, and deactivation",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    // Create profile
    let block = chain.mineBlock([
      Tx.contractCall('skill-tide', 'create-profile', 
        [types.ascii("Web Development"), types.uint(45), types.uint(90)],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk();
    
    // Update profile
    block = chain.mineBlock([
      Tx.contractCall('skill-tide', 'update-profile',
        [types.ascii("Full Stack Dev"), types.uint(46), types.uint(91)],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk();
    
    // Deactivate profile
    block = chain.mineBlock([
      Tx.contractCall('skill-tide', 'deactivate-profile',
        [],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk();
  }
});

// Include original tests...
