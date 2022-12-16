// SPDX-License-Identifier: GPL-3.0
//Author: iknevece@gmail.com

pragma solidity ^0.8.0;

/*
DESCRIPTION
-----------------

It is becoming really difficult to track down illegal colleges. 
Many students' careers are spoiled as they enroll in them.
 
===================================

Background of the problem statement:
-----------------

In many parts of India, illegal colleges are run, which are not affiliated to any university. 
Many students enroll in these colleges without knowing that and in turn they end up having no jobs or colleges get shut down after some time, which ruins their career.

An immutable solution like Blockchain is needed where all the colleges under a university are tracked as blockchain to ensure that no one can modify any old record. That same solution should also allow banning any college to enroll any new student in case there are any complaints against that college. 
Later remove the ban once the college addresses all the complaints.

Recommended technologies:
-----------------
    Smart Contract development: Solidity
    IDE Tool: Remix
    Blockchain: Ethereum
    Server: Ganache Blockchain
*/

contract collegeTracker{

    address public univAdmin;

    constructor(){
        univAdmin = msg.sender;
    }

    modifier onlyAdmin(){
        require(msg.sender == univAdmin, "Only Admin allowed");
        _;
    }

    struct College{
        string collegeName; //The name of the college
        address add; //The unique Ethereum address of the college
        string regNo; //College registration number
        uint8 noOfStudents; //Number of students in the college
        bool isAllowedToAddNewStud; //Allowed to add new student. True or False
    }

    struct Student{
        address add; //The unique address of the college
        string sName; //The name of the student
        uint phoneNo; //The phone number of the student
        string courseName; //The name of the course
    }

    mapping(address => College) public colleges;
    mapping(string => Student) public studentDetails;

    /*
    Features of the application:

    1. Add new college to Blockchain ledger:

    This function is used by the university admin to add a new college. This function can be called by admin only.

    Input parameters:

    param {string} collegeName: The name of the college
    param {address} add: The unique Ethereum address of the college
    param {string} regNo: College registration number
    */

    function addNewCollege(string memory collegeName, address add, string memory regNo) public onlyAdmin {
        require(!(keccak256(bytes(colleges[add].collegeName)) == keccak256(bytes(collegeName))), "College name already exists");
        colleges[add] = College(collegeName, add, regNo, 0, true);
    }

    /*
    2. View college details:

    This function is used to view college details.

    Input Parameters:

    param {address} add: The unique Ethereum address of the college
    Output parameters:

    collegeName: The name of the college
    collegeRegNo: The registration number of the college
    NoOfStudents: Number of students in that college
    */

    function viewCollegeDetails(address add) public view returns (string memory collegeName, string memory collegeRegNo, uint8 NoOfStudents){
        return (colleges[add].collegeName, colleges[add].regNo, colleges[add].noOfStudents);
    }

    /*
    3. Block college to add any new student:

    This function is used by the university admin to block colleges from adding any new students.

    Input parameters:

    param {address} add: The unique Ethereum address of the college
    */

    function blockCollegeToAddNewStudent(address add) public onlyAdmin {
        require(colleges[add].isAllowedToAddNewStud, "College is already blocked to add new student");
        colleges[add].isAllowedToAddNewStud = false;
    }

    /*
    4. UnBlock college to add new students:

    This function is used by the university admin to unblock colleges from adding any new students.

    Input parameters:

    param {address} add: The unique Ethereum address of the college
    */

    function unblockCollegeToAddNewStudent(address add) public onlyAdmin {
        require(!colleges[add].isAllowedToAddNewStud, "College is already allowed to add new student");
        colleges[add].isAllowedToAddNewStud = true;
    }

    /*
    5. Add a new student to the college:

    This function will add a student to the college.

    Input parameters:

    param {address} add: The unique address of the college
    param {string} sName: The name of the student
    param {uint} phoneNo: The phone number of the student
    param {string} courseName: The name of the course
    */

    function addNewStudentToCollege(address add, string memory sName, uint phoneNo, string memory courseName) public {
        require(colleges[add].isAllowedToAddNewStud, "College is already blocked to add new student");
        require(studentDetails[sName].add == address(0), "Student name already exists in the college");
        studentDetails[sName] = Student(add, sName, phoneNo, courseName);
        colleges[add].noOfStudents++;
    }

    /*
    6. View student details:

        This function is used to view student details.

    Input parameters:

    param {string} sName: The name of the student
    Output parameters:

    Name: The name of the student
    PhoneNo: The phone number of the student
    Course Enrolled: Course Enrolled by the student
    */

    function viewStudentDetails(string memory sName) public view returns (string memory Name, uint PhoneNo, string memory CourseEnrolled) {
        require(studentDetails[sName].add != address(0), "Student name doesn't exists");
        return (studentDetails[sName].sName, studentDetails[sName].phoneNo, studentDetails[sName].courseName);
    }

    /*
    7. Change student course:

    This function is used by college admin to change a student's course.

    Input parameters:

    param {address} add: The unique address of the college
    param {string} sName: The name of the student
    param {string} newCourse: The new course name
    */
    function changeStudentCourse(address add, string memory sName, string memory newCourse) public onlyAdmin {
        require(colleges[add].isAllowedToAddNewStud, "No changes allowed as college is already blocked");
        require(studentDetails[sName].add != address(0), "Student name doesn't exists");
        require(keccak256(bytes(studentDetails[sName].courseName)) != keccak256(bytes(newCourse)), "Student has already enrolled for the same course");
        studentDetails[sName] = Student(add, sName, studentDetails[sName].phoneNo, newCourse);
    }
}