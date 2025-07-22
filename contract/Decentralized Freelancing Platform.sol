function rateFreelancer(uint256 _projectId, uint8 _rating) 
    external 
    onlyClient(_projectId) 
    projectExists(_projectId) 
{
    require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");

    FreelanceProject storage project = projects[_projectId];
    require(project.status == ProjectStatus.Completed, "Project is not completed");
    require(project.fundsReleased, "Funds must be released before rating");

    Freelancer storage freelancer = freelancers[project.freelancer];

    // Calculate new average rating
    if (freelancer.completedProjects > 1) {
        uint256 totalRating = freelancer.rating * (freelancer.completedProjects - 1);
        freelancer.rating = (totalRating + _rating) / freelancer.completedProjects;
    } else {
        freelancer.rating = _rating;
    }
}

