package CovidVaccineTracker;

import java.util.Objects;
//import java.util.Date;

import org.hyperledger.fabric.contract.annotation.DataType;
import org.hyperledger.fabric.contract.annotation.Property;

import com.owlike.genson.annotation.JsonProperty;

@DataType()
public class VaccineTracker {
	@Property()
	private final String name;

	@Property()
	private final String age;

	@Property()
	private final String gender;

	@Property()
	private final String identity;

	@Property()
	private final String vaccineRefID;

	@Property()
	private final String vaccineName;

	@Property()
	private final String date;

	@Property()
	private final String vaccineDose;

	public String getName() {
		return name;
	}

	public String getAge() {
		return age;
	}

	public String getGender() {
		return gender;
	}

	public String getIdentity() {
		return identity;
	}

	public String getVaccineRefID() {
		return vaccineRefID;
	}

	public String getVaccineName() {
		return vaccineName;
	}

	public String getDate() {
		return date;
	}

	public String getVaccineDose() {
		return vaccineDose;
	}

	public VaccineTracker(@JsonProperty("identity") final String identity, @JsonProperty("name") final String name,
			@JsonProperty("age") final String age, @JsonProperty("gender") final String gender,
			@JsonProperty("vaccineRefID") final String vaccineRefID,
			@JsonProperty("vaccineName") final String vaccineName, @JsonProperty("date") final String date,
			@JsonProperty("vaccineDose") final String vaccineDose) {
		this.identity = identity;
		this.name = name;
		this.age = age;
		this.gender = gender;
		this.vaccineRefID = vaccineRefID;
		this.vaccineName = vaccineName;
		this.date = date;
		this.vaccineDose = vaccineDose;
	}

	@Override
	public boolean equals(final Object obj) {
		if (this == obj) {
			return true;
		}

		if ((obj == null) || (getClass() != obj.getClass())) {
			return false;
		}

		VaccineTracker other = (VaccineTracker) obj;

		return Objects.deepEquals(
				new String[] { getIdentity(), getName(), getAge(), getGender(), getVaccineRefID(), getVaccineName(),
						getDate(), getVaccineDose() },
				new String[] { other.getIdentity(), other.getName(), other.getAge(), other.getGender(),
						other.getVaccineRefID(), other.getVaccineName(), other.getDate(), other.getVaccineDose() });
	}

	@Override
	public int hashCode() {
		return Objects.hash(getIdentity(), getName(), getAge(), getGender(), getVaccineRefID(), getVaccineName(),
				getDate(), getVaccineDose());
	}

	@Override
	public String toString() {
		return this.getClass().getSimpleName() + "@" + Integer.toHexString(hashCode()) + " [age=" + age + ", date="
				+ date + ", gender=" + gender + ", identity=" + identity + ", name=" + name + ", vaccineDose="
				+ vaccineDose + ", vaccineName=" + vaccineName + ", vaccineRefID=" + vaccineRefID + "]";
	}
}