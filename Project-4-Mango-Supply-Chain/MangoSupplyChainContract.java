package MangoSupplyChain;

import org.hyperledger.fabric.contract.Context;
import org.hyperledger.fabric.contract.ContractInterface;
import org.hyperledger.fabric.contract.annotation.Contract;
import org.hyperledger.fabric.contract.annotation.Default;
import org.hyperledger.fabric.contract.annotation.Info;
import org.hyperledger.fabric.contract.annotation.Transaction;
import org.hyperledger.fabric.shim.ChaincodeException;
import org.hyperledger.fabric.shim.ChaincodeStub;
import com.owlike.genson.Genson;
import java.text.ParseException;

@Contract(name = "MangoSupplyChain", info = @Info(title = "MangoSupplyChain contract", description = "Chaincode for Mango Supply Chain", version = "0.0.1-SNAPSHOT"))

@Default
public final class MangoSupplyChainContract implements ContractInterface {
	private final Genson genson = new Genson();

	private enum MSCErrors {
		ASSET_NOT_FOUND, ASSET_ALREADY_EXISTS, INVALID_INPUT
	}

	/**
	 * Add some initial properties to the ledger
	 *
	 * @param ctx the transaction context
	 */
	@Transaction()
	public void initLedger(final Context ctx) {

		ChaincodeStub stub = ctx.getStub();
		MangoSupplyChain mangosupplychain = new MangoSupplyChain("pr1", "Mango Product 1", "Producer1", "Chennai",
				"1/1/2022", "Distributor1", "Adyar", "5/1/2022", "Retailer1", "Royapettah", "6/1/2022");
		String AssetState = genson.serialize(mangosupplychain);
		stub.putStringState("pr1", AssetState);
	}

	/**
	 *
	 * 1. Add a new asset (mango) to the ledger:
	 *
	 * This function is used to add a new asset (mango) to the ledger. This function
	 * is called by the producer or farmer by using the below parameters:
	 *
	 * Input parameters:
	 * 
	 * @param ctx                the transaction context
	 * @param productId          the product id of the mango
	 * @param productDescription the description of the mango
	 * @param producerName       producer or farmer name
	 * @param producerAddress    producer or farmer address
	 * @param harvestDate        harvest date of the mango
	 * @return the mango details
	 *
	 *         This function does the following check as well:
	 *
	 *         Same asset with the same product ID does not exist already
	 */

	@Transaction()
	public MangoSupplyChain addNewAsset(final Context ctx, final String productId, final String productDescription,
			final String producerName, final String producerAddress, final String harvestDate) {

		ChaincodeStub stub = ctx.getStub();

		String AssetState = stub.getStringState(productId);

		if (!AssetState.isEmpty()) {
			String errorMessage = String.format("Product ID %s already exists", productId);
			System.out.println(errorMessage);
			throw new ChaincodeException(errorMessage, MSCErrors.ASSET_ALREADY_EXISTS.toString());
		}

		MangoSupplyChain mangosupplychain = new MangoSupplyChain(productId, productDescription, producerName,
				producerAddress, harvestDate, "", "", "", "", "", "");

		try {
			if (mangosupplychain.isValidDate(harvestDate)) {
				System.out.printf("%s is Valid date format", harvestDate);
			} else {
				String errorMessage = String.format("Given date %s is invalid. Please enter the date in dd/MM/yyyy format",
						harvestDate);
				System.out.println(errorMessage);
				throw new ChaincodeException(errorMessage, MSCErrors.INVALID_INPUT.toString());
			}
		} catch (ParseException ex) {
//			String errorMessage = String.format("Given date %s is invalid. Please enter the date in dd/MM/yyyy format",
//					harvestDate);
//			System.out.println(errorMessage);
//			throw new ChaincodeException(errorMessage, MSCErrors.INVALID_INPUT.toString());
		}

		AssetState = genson.serialize(mangosupplychain);
		stub.putStringState(productId, AssetState);
		return mangosupplychain;
	}

	/**
	 *
	 * 2. Transfer the asset to distributor from producer:
	 * 
	 * This function helps to transfer the asset from producer (farmer) to
	 * distributor.
	 * 
	 * Input parameters:
	 * 
	 * @param ctx                the transaction context
	 * @param productId          product ID of the mango
	 * @param distributorName    distributor name
	 * @param distributorAddress distributor address
	 * @param prodToDistDate     transaction date between distributor and producer
	 * @return the product id
	 * 
	 *         This function does the following check as well:
	 * 
	 *         The asset should be present in the ledger.
	 * 
	 */
	@Transaction()
	public MangoSupplyChain transferAssetProdToDist(final Context ctx, final String productId,
			final String distributorName, final String distributorAddress, final String prodToDistDate) {
		ChaincodeStub stub = ctx.getStub();

		String AssetState = stub.getStringState(productId);

		if (AssetState.isEmpty()) {
			String errorMessage = String.format("Product ID %s does not exist", productId);
			System.out.println(errorMessage);
			throw new ChaincodeException(errorMessage, MSCErrors.ASSET_NOT_FOUND.toString());
		}
		MangoSupplyChain mangosupplychain = genson.deserialize(AssetState, MangoSupplyChain.class);

		try {
			if (mangosupplychain.isValidDate(prodToDistDate)) {
				System.out.printf("%s is Valid date format", prodToDistDate);
			} else {
				String errorMessage = String.format("Given date %s is invalid. Please enter the date in dd/MM/yyyy format",
						prodToDistDate);
				System.out.println(errorMessage);
				throw new ChaincodeException(errorMessage, MSCErrors.INVALID_INPUT.toString());
			}
		} catch (ParseException ex) {
			ex.printStackTrace();
		}

		try {
			if (mangosupplychain.dateCheck(mangosupplychain.getHarvestDate(), prodToDistDate)) {
				System.out.printf("%s is after %s", prodToDistDate, mangosupplychain.getHarvestDate());
			} else {
				String errorMessage = String.format("Distributor Date %s cannot be in past than Producer date %s",
						prodToDistDate, mangosupplychain.getHarvestDate());
				System.out.println(errorMessage);
				throw new ChaincodeException(errorMessage, MSCErrors.INVALID_INPUT.toString());
			}
		} catch (ParseException ex) {
			ex.printStackTrace();
		}

		MangoSupplyChain updatedmangosupplychain = new MangoSupplyChain(productId,
				mangosupplychain.getProductDescription(), mangosupplychain.getProducerName(),
				mangosupplychain.getProducerAddress(), mangosupplychain.getHarvestDate(), distributorName,
				distributorAddress, prodToDistDate, mangosupplychain.getRetailerName(),
				mangosupplychain.getRetailerAddress(), mangosupplychain.getDistToRetaDate());

		AssetState = genson.serialize(updatedmangosupplychain);
		stub.putStringState(productId, AssetState);
		return updatedmangosupplychain;
	}

	/**
	 *
	 * 3. Transfer the asset to retailer from distributor:
	 * 
	 * This function helps to transfer mango ownership to a retailer from a
	 * distributor.
	 * 
	 * Input parameters:
	 * 
	 * @param ctx             the transaction context
	 * @param productId       product ID of the mango
	 * @param retailerName    retailer name
	 * @param retailerAddress retailer address
	 * @param distToRetaDate  transaction date between distributor and retailer
	 * @return the product id
	 * 
	 *         This function does the following check as well:
	 * 
	 *         The asset should be present in the ledger.
	 * 
	 */
	@Transaction()
	public MangoSupplyChain transferAssetDistToRetailer(final Context ctx, final String productId,
			final String retailerName, final String retailerAddress, final String distToRetaDate) {
		ChaincodeStub stub = ctx.getStub();

		String AssetState = stub.getStringState(productId);

		if (AssetState.isEmpty()) {
			String errorMessage = String.format("Product ID %s does not exist", productId);
			System.out.println(errorMessage);
			throw new ChaincodeException(errorMessage, MSCErrors.ASSET_NOT_FOUND.toString());
		}

		MangoSupplyChain mangosupplychain = genson.deserialize(AssetState, MangoSupplyChain.class);

		try {
			if (mangosupplychain.isValidDate(distToRetaDate)) {
				System.out.printf("%s is Valid date format", distToRetaDate);
			} else {
				String errorMessage = String.format("Given date %s is invalid. Please enter the date in dd/MM/yyyy format",
						distToRetaDate);
				System.out.println(errorMessage);
				throw new ChaincodeException(errorMessage, MSCErrors.INVALID_INPUT.toString());
			}
		} catch (ParseException ex) {
			ex.printStackTrace();
		}

		try {
			if (!mangosupplychain.getProdToDistDate().isEmpty()) {
				if (mangosupplychain.dateCheck(mangosupplychain.getProdToDistDate(), distToRetaDate)) {
					System.out.printf("%s is after %s", distToRetaDate, mangosupplychain.getProdToDistDate());
				} else {
					String errorMessage = String.format("Retailer Date %s cannot be in past than Distributor date %s",
							distToRetaDate, mangosupplychain.getProdToDistDate());
					System.out.println(errorMessage);
					throw new ChaincodeException(errorMessage, MSCErrors.INVALID_INPUT.toString());
				}
			} else {
				String errorMessage = String.format("Cannot update retailer details when Distributor details are empty for the product ID %s", productId);
				System.out.println(errorMessage);
				throw new ChaincodeException(errorMessage, MSCErrors.INVALID_INPUT.toString());
			}
		} catch (ParseException ex) {
			ex.printStackTrace();
		}

		MangoSupplyChain updatedmangosupplychain = new MangoSupplyChain(productId,
				mangosupplychain.getProductDescription(), mangosupplychain.getProducerName(),
				mangosupplychain.getProducerAddress(), mangosupplychain.getHarvestDate(),
				mangosupplychain.getDistributorName(), mangosupplychain.getDistributorAddress(),
				mangosupplychain.getProdToDistDate(), retailerName, retailerAddress, distToRetaDate);

		AssetState = genson.serialize(updatedmangosupplychain);
		stub.putStringState(productId, AssetState);
		return updatedmangosupplychain;
	}

	/*
	 * 4. View asset details from ledger:
	 *
	 * This function helps to retrieve asset product details from the ledger.
	 *
	 * Input parameters
	 *
	 * @param ctx the transaction context
	 * 
	 * @param productId product Id of the mango
	 * 
	 * @return mango supply chain details
	 * 
	 */
	@Transaction()
	public MangoSupplyChain viewAssetDetails(final Context ctx, final String productId) {
		ChaincodeStub stub = ctx.getStub();

		String AssetState = stub.getStringState(productId);

		if (AssetState.isEmpty()) {
			String errorMessage = String.format("Product ID %s does not exist", productId);
			System.out.println(errorMessage);
			throw new ChaincodeException(errorMessage, MSCErrors.ASSET_NOT_FOUND.toString());
		}

		MangoSupplyChain mangosupplychain = genson.deserialize(AssetState, MangoSupplyChain.class);
		return mangosupplychain;
	}
}
