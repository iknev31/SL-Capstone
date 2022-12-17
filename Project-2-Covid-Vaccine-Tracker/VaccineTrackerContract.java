package CovidVaccineTracker;

import org.hyperledger.fabric.contract.Context;
import org.hyperledger.fabric.contract.ContractInterface;
import org.hyperledger.fabric.contract.annotation.Contract;
import org.hyperledger.fabric.contract.annotation.Default;
import org.hyperledger.fabric.contract.annotation.Info;
import org.hyperledger.fabric.contract.annotation.Transaction;
import org.hyperledger.fabric.shim.ChaincodeException;
import org.hyperledger.fabric.shim.ChaincodeStub;
import java.util.*;
import com.owlike.genson.Genson;

@Contract(name = "CovidVaccineTracker", info = @Info(title = "CovidVaccineTracker contract", description = "Chaincode for Covid Vaccine Tracker", version = "0.0.1-SNAPSHOT"))

@Default
public final class VaccineTrackerContract implements ContractInterface {
	private final Genson genson = new Genson();

	private enum VaccineTrackerErrors {
		Beneficiary_NOT_FOUND, Beneficiary_ALREADY_EXISTS, Beneficiary_FULLY_VACCINATED, Beneficiary_VACCINE_MISMATCH, INVALID_INPUT
	}
	
	/**
	 * Add some initial properties to the ledger
	 *
	 * @param ctx the transaction context
	 */
	@Transaction()
	public void initLedger(final Context ctx) {

		ChaincodeStub stub = ctx.getStub();
		VaccineTracker vaccinetracker = new VaccineTracker("benid123", "beneficiary1", "20", "male", "vacrefid1",
				"covaxin", "1/1/2021", "first");
		String BeneficiaryState = genson.serialize(vaccinetracker);
		stub.putStringState("benid123", BeneficiaryState);
	}

	/**
	 *
	 * 1. Adds first dose recipients of the vaccine: This function is used to add a
	 * recipient who has received the very first dose of covid vaccine.
	 *
	 * Input parameters:
	 *
	 * @param name        the name of the recipient
	 * @param age         the age of the recipient
	 * @param gender      the gender of the recipient
	 * @param identity    the identity proof of the recipient
	 * @param vaccineName the name of the vaccine
	 * @param date        the date of the vaccine administration
	 * @param vaccineDose the dose number of the vaccine
	 *
	 *                    This function does the following checks as well: Recipient
	 *                    should not have taken second dose of the vaccine Recipient
	 *                    should not have taken both the doses of the vaccine
	 *
	 */

	@Transaction()
	public VaccineTracker addNewRecipientFirstDose(final Context ctx, final String identity, final String name,
			final String age, final String gender, final String vaccineRefID, final String vaccineName,
			final String date, final String vaccineDose) {

		ChaincodeStub stub = ctx.getStub();
		
		ArrayList<String> ApprovedVaccines = new ArrayList<String>(
	            Arrays.asList("covaxin", "covishield", "covilo", "coronovac", "sputnik"));
		
		ArrayList<String> Genders = new ArrayList<String>(
	            Arrays.asList("male", "female", "transgender"));
		
		if (!ApprovedVaccines.contains(vaccineName.toLowerCase())) {
			String errorMessage = String.format(
					"Cannot add the unapproved vaccine %s to the ledger. Approved vaccines are covaxin, covishield, covilo, coronovac, sputnik",
					vaccineName);
			System.out.println(errorMessage);
			throw new ChaincodeException(errorMessage, VaccineTrackerErrors.INVALID_INPUT.toString());
		}
		
		if (!Genders.contains(gender.toLowerCase())) {
			String errorMessage = String.format(
					"Add the gender as male or female or transgender.",
					gender);
			System.out.println(errorMessage);
			throw new ChaincodeException(errorMessage, VaccineTrackerErrors.INVALID_INPUT.toString());
		}
		
		String BeneficiaryState = stub.getStringState(identity);

		if (!BeneficiaryState.isEmpty()) {
			String errorMessage = String.format("Beneficiary already exists with the identity %s", identity);
			System.out.println(errorMessage);
			throw new ChaincodeException(errorMessage, VaccineTrackerErrors.Beneficiary_ALREADY_EXISTS.toString());
		}

		if (!vaccineDose.toLowerCase().equalsIgnoreCase("first")) {
			String errorMessage = String.format(
					"First dose details for the Beneficiary with the identity %s is not available. Please add first dose details.",
					identity);
			System.out.println(errorMessage);
			throw new ChaincodeException(errorMessage, VaccineTrackerErrors.Beneficiary_NOT_FOUND.toString());
		}

		VaccineTracker vaccinetracker = new VaccineTracker(identity, name, age, gender, vaccineRefID, vaccineName, date,
				vaccineDose);
		BeneficiaryState = genson.serialize(vaccinetracker);
		stub.putStringState(identity, BeneficiaryState);
		return vaccinetracker;
	}

	/**
	 *
	 * 2. View covid vaccination status:
	 *
	 * This function helps to check if a person is vaccinated or not. If yes, then
	 * how many doses they have taken.
	 *
	 * Input parameters:
	 *
	 * @param identity the identity proof of the recipient
	 *
	 *                 This function returns the status of the person.
	 *
	 */
	@Transaction()
	public VaccineTracker queryVaccineStatusByIdentity(final Context ctx, final String identity) {
		ChaincodeStub stub = ctx.getStub();

		String BeneficiaryState = stub.getStringState(identity);

		if (BeneficiaryState.isEmpty()) {
			String errorMessage = String.format("Beneficiary with identity proof %s does not exist", identity);
			System.out.println(errorMessage);
			throw new ChaincodeException(errorMessage, VaccineTrackerErrors.Beneficiary_NOT_FOUND.toString());
		}

		VaccineTracker vaccinetracker = genson.deserialize(BeneficiaryState, VaccineTracker.class);
		return vaccinetracker;
	}

	/**
	 *
	 * 3. Update the status of the recipient after the second dose:
	 *
	 * This function helps to check and update the ledger when the recipient takes a
	 * second dose of the vaccine.
	 *
	 * Input parameters:
	 *
	 * @param identity the identity proof of the recipient
	 * @param date     the date of the vaccine administration
	 *
	 *                 This function does the following checks as well: Recipient
	 *                 should be given the first dose of the same vaccine Recipient
	 *                 should not be fully vaccinated already
	 *
	 */
	@Transaction()
	public VaccineTracker updateRecipientSecondDose(final Context ctx, final String identity, final String date) {
		ChaincodeStub stub = ctx.getStub();

		String BeneficiaryState = stub.getStringState(identity);

		if (BeneficiaryState.isEmpty()) {
			String errorMessage = String.format("Beneficiary with identity proof %s does not exist", identity);
			System.out.println(errorMessage);
			throw new ChaincodeException(errorMessage, VaccineTrackerErrors.Beneficiary_NOT_FOUND.toString());
		}

		VaccineTracker vaccinetracker = genson.deserialize(BeneficiaryState, VaccineTracker.class);

		String doseNumber = vaccinetracker.getVaccineDose().toString();
		if (doseNumber.toLowerCase().equalsIgnoreCase("second")) {
			String errorMessage = String.format("Beneficiary with identity proof %s is already fully vaccinated",
					identity);
			System.out.println(errorMessage);
			throw new ChaincodeException(errorMessage, VaccineTrackerErrors.Beneficiary_FULLY_VACCINATED.toString());
		}

		VaccineTracker updateVaccineTracker = new VaccineTracker(identity, vaccinetracker.getName(),
				vaccinetracker.getAge(), vaccinetracker.getGender(), vaccinetracker.getVaccineRefID(),
				vaccinetracker.getVaccineName(), date, "second");

		String updateBeneficiaryState = genson.serialize(updateVaccineTracker);
		stub.putStringState(identity, updateBeneficiaryState);
		return updateVaccineTracker;
	}
}
