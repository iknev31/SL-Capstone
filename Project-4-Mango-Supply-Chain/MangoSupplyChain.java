package MangoSupplyChain;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Objects;
import org.hyperledger.fabric.contract.annotation.DataType;
import org.hyperledger.fabric.contract.annotation.Property;
import com.owlike.genson.annotation.JsonProperty;

@DataType()
public class MangoSupplyChain {
	@Property()
	private final String productId;

	@Property()
	private final String productDescription;

	@Property()
	private final String producerName;

	@Property()
	private final String producerAddress;

	@Property()
	private final String harvestDate;

	@Property()
	private final String distributorName;

	@Property()
	private final String distributorAddress;

	@Property()
	private final String prodToDistDate;

	@Property()
	private final String retailerName;

	@Property()
	private final String retailerAddress;

	@Property()
	private final String distToRetaDate;

	public String getProductId() {
		return productId;
	}

	public String getProductDescription() {
		return productDescription;
	}

	public String getProducerName() {
		return producerName;
	}

	public String getProducerAddress() {
		return producerAddress;
	}

	public String getHarvestDate() {
		return harvestDate;
	}

	public String getDistributorName() {
		return distributorName;
	}

	public String getDistributorAddress() {
		return distributorAddress;
	}

	public String getProdToDistDate() {
		return prodToDistDate;
	}

	public String getRetailerName() {
		return retailerName;
	}

	public String getRetailerAddress() {
		return retailerAddress;
	}

	public String getDistToRetaDate() {
		return distToRetaDate;
	}

	public MangoSupplyChain(@JsonProperty("productId") final String productId,
			@JsonProperty("productDescription") final String productDescription,
			@JsonProperty("producerName") final String producerName,
			@JsonProperty("producerAddress") final String producerAddress,
			@JsonProperty("harvestDate") final String harvestDate,
			@JsonProperty("distributorName") final String distributorName,
			@JsonProperty("distributorAddress") final String distributorAddress,
			@JsonProperty("prodToDistDate") final String prodToDistDate,
			@JsonProperty("retailerName") final String retailerName,
			@JsonProperty("retailerAddress") final String retailerAddress,
			@JsonProperty("distToRetaDate") final String distToRetaDate) {

		this.productId = productId;
		this.productDescription = productDescription;
		this.producerName = producerName;
		this.producerAddress = producerAddress;
		this.harvestDate = harvestDate;
		this.distributorName = distributorName;
		this.distributorAddress = distributorAddress;
		this.prodToDistDate = prodToDistDate;
		this.retailerName = retailerName;
		this.retailerAddress = retailerAddress;
		this.distToRetaDate = distToRetaDate;
	}

	@Override
	public boolean equals(final Object obj) {
		if (this == obj) {
			return true;
		}

		if ((obj == null) || (getClass() != obj.getClass())) {
			return false;
		}

		MangoSupplyChain other = (MangoSupplyChain) obj;

		return Objects.deepEquals(
				new String[] { getProductId(), getProductDescription(), getProducerName(), getProducerAddress(),
						getHarvestDate(), getDistributorName(), getDistributorAddress(), getProdToDistDate(),
						getRetailerName(), getRetailerAddress(), getDistToRetaDate() },
				new String[] { other.getProductId(), other.getProductDescription(), other.getProducerName(),
						other.getProducerAddress(), other.getHarvestDate(), other.getDistributorName(),
						other.getDistributorAddress(), other.getProdToDistDate(), other.getRetailerName(),
						other.getRetailerAddress(), other.getDistToRetaDate() });
	}

	@Override
	public int hashCode() {
		return Objects.hash(getProductId(), getProductDescription(), getProducerName(), getProducerAddress(),
				getHarvestDate(), getDistributorName(), getDistributorAddress(), getProdToDistDate(), getRetailerName(),
				getRetailerAddress(), getDistToRetaDate());
	}

	@Override
	public String toString() {
		return this.getClass().getSimpleName() + "@" + Integer.toHexString(hashCode()) + " [productId=" + productId
				+ ", productDescription=" + productDescription + ", producerName=" + producerName + ", producerAddress="
				+ producerAddress + ", harvestDate=" + harvestDate + ", distributorName=" + distributorName
				+ ", distributorAddress=" + distributorAddress + ", prodToDistDate=" + prodToDistDate
				+ ", retailerName=" + retailerName + ",retailerAddress=" + retailerAddress + "distToRetaDate="
				+ distToRetaDate + "]";
	}

	/*
	 * Validate the date input
	 */

	public boolean isValidDate(String dateStr) throws ParseException {
		Date date = null;
		try {
			SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
			date = sdf.parse(dateStr);
			if (!dateStr.equals(sdf.format(date))) {
				date = null;
			}
		} catch (ParseException ex) {
			ex.printStackTrace();
		}
		return date != null;
	}

	/*
	 * Compare two dates in String format
	 */
	public boolean dateCheck(String dateStr1, String dateStr2) throws ParseException {
		boolean result = false;
		try {
			SimpleDateFormat sdf = new SimpleDateFormat("dd/MM/yyyy");
			// Parsing the given String to Date object
			Date date1 = sdf.parse(dateStr1);
			Date date2 = sdf.parse(dateStr2);
			Boolean bool1 = date2.after(date1);
			if (bool1) {
				System.out.println(dateStr2 + " is after " + dateStr1);
				result = true;
			} else {
				System.out.println(dateStr2 + " is before " + dateStr1);
				result = false;
			}
		} catch (ParseException ex) {
			ex.printStackTrace();
		}
		return result;
	}
}
