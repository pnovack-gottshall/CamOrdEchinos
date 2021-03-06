## Modified MorphDistMatrix() function from 'Claddis' package that silences line
## [original] 396 to avoid triggering CharDepends error (which in the
## morphological case is not really an error because the dependencies are not
## always straightforward when coding phylum-wide characters.) Code by Graeme
## Lloyd and taken from
## https://github.com/graemetlloyd/Claddis/blob/master/R/MorphDistMatrix.R.
## Downloaded 7/2/2020. Thanks, Graeme!

# Note that substantial coding changes accompanied the update to Claddis v.
# 0.6.0 in August 2020. The code here uses the functions as of 7/2/2020, v.
# 0.4.1. Future users will need to either download the archived version of the
# package from GitHub or alter the code accordingly to use the current argument
# and function names.

MorphDistMatrix2 <- function(CladisticMatrix, Distance = "MORD", GEDType = "Wills", TransformDistances = "arcsine_sqrt", PolymorphismBehaviour = "min.difference", UncertaintyBehaviour = "min.difference", InapplicableBehaviour = "missing", CharacterDependencies = NULL, Alpha = 0.5) {
  
  # ADD HOPKINS SUGGESTION (VIA EMAIL) FOR FOURTH GEDTYPE WHERE MEAN DISTANCE FOR CHARACTER REPLACES MISSING VALUES.
  # CHECK POLYMORPHISM UNCERTAINTY IN GENERAL AS NOT CLEAR IT IS DOING WHAT IT SHOULD DO.
  # CHECK TRASNFORM IS APPROPRIATE AND WARN USER IF NOT
  # MAYBE ALLOW MANHATTAN TYPE DISTANCES TOO.
  # ADD LEHAMN REFERENCE!
  
  # Subfunction to find comparable characters for a pairwise taxon comparison:
  GetComparableCharacters <- function(interest.col, CladisticMatrix) {
    
    # Get intersection of characters that are coded for both taxa in a pair:
    output <- intersect(intersect(which(!is.na(CladisticMatrix[interest.col[[1]], ])), which(CladisticMatrix[interest.col[[1]], ] != "")), intersect(which(!is.na(CladisticMatrix[interest.col[[2]], ])), which(CladisticMatrix[interest.col[[2]], ] != "")))
    
    # Return output:
    return(list(output))
    
  }
  
  # Subfunction to get character strings for each pair of taxa:
  GetPairwiseCharacterStrings <- function(interest.col, CladisticMatrix) {
    
    # Get character states for first taxon in pair:
    row1 <- CladisticMatrix[rownames(CladisticMatrix)[interest.col[[1]]], ]
    
    # Get character states for second taxon in pair:
    row2 <- CladisticMatrix[rownames(CladisticMatrix)[interest.col[[2]]], ]
    
    # Return output as a list:
    return(list(row1, row2))
    
  }
  
  # Subfunction to subset pairwise comparisons by just comparable characters:
  SubsetPairwiseByComparable <- function(row.pair, comparable.characters) {
    
    # Collapse first row to just comparable characters:
    row.pair[[1]] <- row.pair[[1]][comparable.characters]
    
    # Collapse second row to just comparable characters:
    row.pair[[2]] <- row.pair[[2]][comparable.characters]
    
    # Output colapsed row pair:
    return(row.pair)
    
  }
  
  # Subfunction to edit polymorphic characters down to a single value:
  EditPolymorphisms <- function(comparisons, comparable.characters, ordering, PolymorphismBehaviour, UncertaintyBehaviour) {
    
    # Set first taxon values:
    firstrow <- comparisons[[1]]
    
    # Set second taxon values:
    secondrow <- comparisons[[2]]
    
    # If there are any inapplicables:
    if(any(c(firstrow, secondrow) == "")) {
      
      # Find inapplicable positions:
      InapplicablePositions <- sort(unique(c(which(firstrow == ""), which(secondrow == ""))))
      
      # Find polymorphism and uncertainty positions:
      PolymorphismAndUncertaintyPositions <- sort(unique(c(grep("/|&", firstrow), grep("/|&", secondrow))))
      
      # If there are polymorphisms or uncertianties that match up with inapplicables:
      if(length(intersect(InapplicablePositions, PolymorphismAndUncertaintyPositions)) > 0) {
        
        # Find positions where collapsing to a single value is required:
        CollapsePositions <- intersect(InapplicablePositions, PolymorphismAndUncertaintyPositions)
        
        # Collapse any polymorphisms or uncertianties in first row to just first value:
        firstrow[CollapsePositions] <- unlist(lapply(strsplit(firstrow[CollapsePositions], split = "/|&"), function(x) ifelse(length(x) == 0, "", x[1])))
        
        # Collapse any polymorphisms or uncertianties in second row to just first value:
        secondrow[CollapsePositions] <- unlist(lapply(strsplit(secondrow[CollapsePositions], split = "/|&"), function(x) ifelse(length(x) == 0, "", x[1])))
        
      }
      
    }
    
    # Set comparable characters:
    compchar <- comparable.characters
    
    # Set ordering for comparable characters:
    charordering <- ordering[compchar]
    
    # Only if there are polymorphisms or uncertainties:
    if(length(c(grep("&", unique(c(firstrow, secondrow))), grep("/", unique(c(firstrow, secondrow))))) > 0) {
      
      # Find ampersands (polymorphisms):
      ampersand.elements <- sort(c(grep("&", firstrow), grep("&", secondrow)))
      
      # Find slashes (uncertianties):
      slash.elements <- sort(c(grep("/", firstrow), grep("/", secondrow)))
      
      # Combine to find all characters to check:
      characters.to.check <- sort(unique(c(ampersand.elements, slash.elements)))
      
      # Set behaviours as either the shared version or minimum difference if they contradict (may need to modify this later for more complex options):
      behaviour <- unlist(lapply(lapply(lapply(lapply(lapply(lapply(lapply(apply(apply(rbind(firstrow[characters.to.check], secondrow[characters.to.check]), 2, gsub, pattern = "[:0-9:]", replacement = ""), 2, list), unlist), function(x) x[nchar(x) > 0]), function(x) ifelse(nchar(x) > 0, strsplit(x, split = "")[[1]][1], x)), function(x) gsub(x, pattern = "&", replacement = PolymorphismBehaviour)), function(x) gsub(x, pattern = "/", replacement = UncertaintyBehaviour)), unique), function(x) ifelse(length(x) > 1, "min.difference", x)))
      
      # If behaviour is to find minimum differences:
      if(any(behaviour == "min.difference")) {
        
        # Set up minimum difference characters to check:
        min.characters.to.check <- characters.to.check[behaviour == "min.difference"]
        
        # Find intersecting character states for each character:
        IntersectionCharacter <- lapply(lapply(lapply(lapply(apply(rbind(firstrow[min.characters.to.check], secondrow[min.characters.to.check]), 2, strsplit, split = "&|/"), unlist), sort), rle), function(x) x$values[x$lengths > 1][1])
        
        # If at least one intersecting character state was found:
        if(any(!is.na(unlist(IntersectionCharacter)))) {
          
          # Record rows to update:
          rows.to.update <- which(!is.na(unlist(IntersectionCharacter)))
          
          # Store (first) shared state for both taxa:
          firstrow[min.characters.to.check[rows.to.update]] <- secondrow[min.characters.to.check[rows.to.update]] <- unlist(IntersectionCharacter)[rows.to.update]
          
          # Update minimum characters to check:
          min.characters.to.check <- min.characters.to.check[-rows.to.update]
          
        }
        
        # Only continue if there are still characters that need to be fixed:
        if(length(min.characters.to.check) > 0) {
          
          # Build two option matrices for every comparison:
          TwoOptionMatrices <- lapply(apply(rbind(firstrow[min.characters.to.check], secondrow[min.characters.to.check]), 2, strsplit, split = "&|/"), function(x) rbind(c(min(as.numeric(x[[1]])), max(as.numeric(x[[2]]))), c(max(as.numeric(x[[1]])), min(as.numeric(x[[2]])))))
          
          # Pick smallest difference as minimum and maximum states:
          MinMaxStates <- lapply(lapply(lapply(TwoOptionMatrices, function(x) x[which(abs(apply(x, 1, diff)) == min(abs(apply(x, 1, diff)))), ]), sort), as.character)
          
          # Set first row values(s):
          firstrow[min.characters.to.check] <- unlist(lapply(MinMaxStates, '[[', 1))
          
          # Set second row values(s):
          secondrow[min.characters.to.check] <- unlist(lapply(MinMaxStates, '[[', 2))
          
        }
        
      }
      
      # If any behaviour is to find mean differences:
      if(any(behaviour == "mean.difference")) {
        
        # Set up minimum difference characters to check:
        mean.characters.to.check <- characters.to.check[behaviour == "mean.difference"]
        
        # Build initial state matrices with column and row names as states for first and second rows:
        StateMatrices <- lapply(lapply(apply(rbind(firstrow[mean.characters.to.check], secondrow[mean.characters.to.check]), 2, list), lapply, strsplit, split = "&|/"), function(x) matrix(nrow = length(x[[1]][[1]]), ncol = length(x[[1]][[2]]), dimnames = list(x[[1]][[1]], x[[1]][[2]])))
        
        # Fill state matrices with raw differences between each state:
        StateMatrices <- lapply(StateMatrices, function(x) { for(i in 1:ncol(x)) for(j in 1:nrow(x)) x[j, i] <- abs(as.numeric(colnames(x)[i]) - as.numeric(rownames(x)[j])) ; return(x) })
        
        # If there are unordered characters present convert maximum distances to one:
        if(any(charordering[mean.characters.to.check] == "unord")) StateMatrices[which(charordering[mean.characters.to.check] == "unord")] <- lapply(StateMatrices[which(charordering[mean.characters.to.check] == "unord")], function(x) { x[x > 1] <- 1; return(x) })
        
        # Extract minimum and maximum states from each matrix with maximum being the mean distance:
        MinMaxStates <- lapply(lapply(lapply(StateMatrices, as.vector), mean), function(x) c(0, x))
        
        # Set first row values(s):
        firstrow[mean.characters.to.check] <- unlist(lapply(MinMaxStates, '[[', 1))
        
        # Set second row values(s):
        secondrow[mean.characters.to.check] <- unlist(lapply(MinMaxStates, '[[', 2))
        
      }
      
    }
    
    # Return the first and second rows either without polymorphisms or with them removed:
    return(list(firstrow, secondrow))
    
  }
  
  # Subfunction to get the absolute difference between the two rows:
  GetAbsoluteCharacterDifferences <- function(column) {
    
    # Isolate first row values:
    firstrow <- column[[1]]
    
    # Isolate second row values:
    secondrow <- column[[2]]
    
    # Get absolute differences between each pair of characters:
    return(list(abs(as.numeric(firstrow) - as.numeric(secondrow))))
    
  }
  
  # Subfunction to correct unordered distances to one::
  CorrectForUnordered <- function(differences, compchar, ordering) {
    
    # If unordered and distance greater than one replace with one:
    if(length(which(differences > 1)) > 0) differences[which(differences > 1)[which(ordering[compchar[which(differences > 1)]] == "unord")]] <- 1
    
    # Return corrected unordered distances:
    return(list(differences))
    
  }
  
  # Subfunction to find incomparable characters:
  FindIncomparableCharacters <- function(comparable.characters, CladisticMatrix) return(setdiff(1:ncol(CladisticMatrix), comparable.characters))
  
  # Subfunction to get weighted differences:
  WeightDifferences <- function(differences, comparable.characters, weights) return(list(as.numeric(weights[comparable.characters]) * differences))
  
  # Subfunction to get raw Euclidean distance:
  RawEuclideanDistance <- function(differences) return(dist(rbind(differences, rep(0, length(differences))), method = "euclidean"))
  
  # Subfunction to find maximum possible differences for the comparable characters:
  MaximumDIfferences <- function(comparable.characters, max.vals, min.vals) return(as.numeric(max.vals[comparable.characters]) - as.numeric(min.vals[comparable.characters]))
  
  # Subfunction to transform list of distances into an actual distance matrix:
  ConvertListToMatrix <- function(list, CladisticMatrix, diag = NULL) {
    
    # Set the number of rows:
    k <- nrow(CladisticMatrix)
    
    # Create the empty matrix:
    mat.out <- matrix(ncol = k, nrow = k)
    
    # Fill up the lower triangle:
    mat.out[lower.tri(mat.out)] <- unlist(list)
    
    # Make the matrix a distance matrix (both triangles have the same values):
    mat.out <- as.matrix(as.dist(mat.out))
    
    # If no diagonal is supplied:
    if(is.null(diag)) {
      
      # Set diagonal as zero:
      diag(mat.out) <- 0
      
      # If a diagonal is supplied:
    } else {
      
      # Add supplied diagonal as diagonal:
      diag(mat.out) <- diag
      
    }
    
    # Return matrix:
    return(mat.out)
    
  }
  
  # Subfunction to get count of complete characters for each taxon (diagonal in comparable characters matrix:
  CountCompleteCharacters <- function(column) return(length(column) - length(grep(TRUE, is.na(column))))
  
  # Subfunction to calculate the Gower Coefficient:
  CalculateGowerCoefficient <- function(differences, comparable.characters, weights) return(sum(differences) / sum(weights[comparable.characters]))
  
  # Subfunction to calculate MORD:
  CalculateMORD <- function(differences, maximum.differences) return(sum(differences) / sum(maximum.differences))
  
  # Subfunction for building starting GED data:
  BuildStartingGEDData <- function(differences, comparable.characters, CladisticMatrix, weights) return(rbind(c(differences, rep(NA, length(FindIncomparableCharacters(comparable.characters, CladisticMatrix)))), c(weights[comparable.characters], weights[FindIncomparableCharacters(comparable.characters, CladisticMatrix)])))
  
  # Subfunction to apply Hopkins and St John (2018) Alpha weighting of inapplicables:
  AlphaWeightingOfInapplicables <- function(diffs, comparable.characters, ordering, weights, CharacterDependencies, CharactersByLevel, Alpha) {
    
    # Set differences:
    Differences <- diffs
    
    # Set comparable characters:
    ComparableCharacters <- comparable.characters
    
    # Set ordering for comparable characters:
    CharacterOrdering <- ordering[ComparableCharacters]
    
    # Set ordering for comparable characters:
    Weights <- weights[ComparableCharacters]
    
    # Fof each character level (from most to least nested):
    for(i in length(CharactersByLevel):2) {
      
      # Get independent characters for current levels dependent characters:
      IndependentCharacters <- unique(unlist(lapply(as.list(CharactersByLevel[[i]]), function(x) unname(CharacterDependencies[CharacterDependencies[, "DependentCharacter"] == x, "IndependentCharacter"]))))
      
      # For each independent character:
      for(j in IndependentCharacters) {
        
        # Find dependent characters:
        DependentCharacters <- unname(CharacterDependencies[CharacterDependencies[, "IndependentCharacter"] == j, "DependentCharacter"])
        
        # Check characters are present in current distance:
        CharactersPresent <- intersect(ComparableCharacters, DependentCharacters)
        
        # If characters are present:
        if(length(CharactersPresent) > 0) {
          
          # Set positions of dependent characters in current differences vector:
          DependentPositions <- match(CharactersPresent, ComparableCharacters)
          
          # Get position of independent character in current differences vector:
          IndependentPosition <- which(ComparableCharacters == j)
          
          # THIS IS THE ERROR THAT GETS TRIGGERED: SILENCED
          # Stop and warn user if matrix contains an impossible coding (i.e., dependent character coded when independent character is missing):
          # if(length(IndependentPosition) == 0) stop("Found a dependent character coded when character it depends on is missing. Check matrix codings.")
          
          # Overwrite independent position with alpha-weighted value:
          diffs[IndependentPosition] <- 1 - (Alpha * (1 - (sum(diffs[DependentPositions] * Weights[DependentPositions]) / sum(Weights[DependentPositions]))) + (1 - Alpha))
          
          # Overwrite dependent positions with NAs:
          diffs[DependentPositions] <- NA
          
        }
        
      }
      
    }
    
    # Return modified character comparisons:
    return(diffs)
    
  }
  
  # Check for step matrices and stop and warn user if found:
  if(is.list(CladisticMatrix$Topper$StepMatrices)) stop("Function cannot currently deal with step matrices.")
  
  # Check input of TransformDistances is valid and stop and warn if not:
  if(length(setdiff(TransformDistances, c("arcsine_sqrt", "none", "sqrt"))) > 0) stop("TransformDistances must be one of \"none\", \"sqrt\", or \"arcsine_sqrt\".")
  
  # Check input of distance is valid and stop and warn if not:
  if(length(setdiff(Distance, c("RED", "GED", "GC", "MORD"))) > 0) stop("Distance must be one or more of \"RED\", \"GED\", \"GC\", or \"MORD\".")
  
  # Check input of GED type is valid and stop and warn if not:
  if(length(setdiff(GEDType, c("Legacy", "Hybrid", "Wills"))) > 0) stop("GEDType must be one or more of \"Legacy\", \"Hybrid\", or \"Wills\".")
  
  # Check input for PolymorphismBehaviour is valid and stop and warn if not:
  if(length(setdiff(PolymorphismBehaviour, c("mean.difference", "min.difference", "random"))) > 0) stop("PolymorphismBehaviour must be one or more of \"mean.difference\", \"min.difference\", or \"random\".")
  
  # Check input for UncertaintyBehaviour is valid and stop and warn if not:
  if(length(setdiff(UncertaintyBehaviour, c("mean.difference", "min.difference", "random"))) > 0) stop("UncertaintyBehaviour must be one or more of \"mean.difference\", \"min.difference\", or \"random\".")
  
  # Check input for InapplicableBehaviour is valid and stop and warn if not:
  if(length(setdiff(InapplicableBehaviour, c("missing", "HSJ"))) > 0) stop("InapplicableBehaviour must be one or more of \"missing\", or \"HSJ\".")
  
  # Check that if using HSJ character dependencies have been specified:
  if(InapplicableBehaviour == "HSJ" && is.null(CharacterDependencies)) stop("If using the \"HSJ\" InapplicableBehaviour then CharacterDependencies must be specified.")
  
  # If using HSJ and CharacterDependencies is set (will check data are formatted correctly):
  if(InapplicableBehaviour == "HSJ" && !is.null(CharacterDependencies)) {
    
    # Check CharacterDependencies is a matrix and stop and warn user if not:
    if(!is.matrix(CharacterDependencies)) stop("CharacterDependencies must be in the form of a two-column matrix.")
    
    # Check CharacterDependencies has two columns and stop and warn user if not:
    if(ncol(CharacterDependencies) != 2) stop("CharacterDependencies must be in the form of a two-column matrix.")
    
    # Check CharacterDependencies column names are correct and stop and warn user if not:
    if(length(setdiff(c("DependentCharacter", "IndependentCharacter"), colnames(CharacterDependencies))) > 0) stop("CharacterDependencies column names must be exactly \"DependentCharacter\" and \"IndependentCharacter\".")
    
    # Check CharacterDependencies are numeric values and stop and warn user if not:
    if(!is.numeric(CharacterDependencies)) stop("CharacterDependencies values must be numeric.")
    
    # Check CharacterDependencies values are within range of matrix dimensions and stop and warn user if not:
    if(length(setdiff(as.vector(CharacterDependencies), 1:sum(unname(unlist(lapply(CladisticMatrix[2:length(CladisticMatrix)], function(x) ncol(x$Matrix))))))) > 0) stop("CharacterDependencies can only contain character numbers within the dimensions of the CladisticMatrix specified.")
    
    # Check CharacterDependencies values do not lead to duplicated parent characters and stop and warn user if not:
    if(any(duplicated(CharacterDependencies[, "DependentCharacter"]))) stop("CharacterDependencies characters can not be dependent on two or more different independent characters.")
    
    # Find any characters that are both dependent and independent (and hence may lead to circularity issues):
    CharactersToCheckForCircularDependency <- intersect(CharacterDependencies[, "DependentCharacter"], CharacterDependencies[, "IndependentCharacter"])
    
    # If there is the possibility for circularity:
    if(length(CharactersToCheckForCircularDependency) > 0) {
      
      # For the ith independent character:
      for(i in unique(CharacterDependencies[, "IndependentCharacter"])) {
        
        # Set current character as ith character:
        CurrentCharacter <- i
        
        # Ste starting found character as ith character:
        FoundCharacters <- i
        
        # Keep going until the current character is not an independent character:
        while(sum(unlist(lapply(as.list(CurrentCharacter), function(x) sum(CharacterDependencies[, "IndependentCharacter"] == x)))) > 0) {
          
          # Find any dependent character(s):
          DependentCharacter <- unlist(lapply(as.list(CurrentCharacter), function(x) unname(CharacterDependencies[CharacterDependencies[, "IndependentCharacter"] == x, "DependentCharacter"])))
          
          # Check character was not already found (creating a circularity) and stop and wanr user if true:
          if(length(intersect(DependentCharacter, FoundCharacters)) > 0) stop("Circularity found in CharacterDependencies.")
          
          # Update found characters:
          FoundCharacters <- c(FoundCharacters, DependentCharacter)
          
          # Update current character(s):
          CurrentCharacter <- DependentCharacter
          
        }
        
      }
      
    }
    
    # Check alpha is a value between zero and one and stop and warn user if not:
    if(Alpha > 1 || Alpha < 0) stop("Alpha must be a value between zero and one")
    
  }
  
  # Isolate ordering element:
  ordering <- unname(unlist(lapply(CladisticMatrix[2:length(CladisticMatrix)], '[[', "Ordering")))
  
  # Isolate minimum values:
  min.vals <- unname(unlist(lapply(CladisticMatrix[2:length(CladisticMatrix)], '[[', "MinVals")))
  
  # Isolate maximum values:
  max.vals <- unname(unlist(lapply(CladisticMatrix[2:length(CladisticMatrix)], '[[', "MaxVals")))
  
  # Isolate weights:
  weights <- unname(unlist(lapply(CladisticMatrix[2:length(CladisticMatrix)], '[[', "Weights")))
  
  # Combine matrix blocks into a single matrix:
  CladisticMatrix <- do.call(cbind, lapply(CladisticMatrix[2:length(CladisticMatrix)], '[[', "Matrix"))
  
  # If PolymorphismBehaviour is to randomly sample one state:
  if(PolymorphismBehaviour == "random") {
    
    # Find cells with polymorphisms:
    PolymorphismCells <- grep("&", CladisticMatrix)
    
    # If there are polymorphisms randomly sample one value and store:
    if(length(PolymorphismCells) > 0) CladisticMatrix[PolymorphismCells] <- unlist(lapply(as.list(CladisticMatrix[PolymorphismCells]), function(x) sample(strsplit(x, split = "&")[[1]], size = 1)))
    
    # Reset behaviour as mean difference to allow it to interact correctly with UncertaintyBehaviour later:
    PolymorphismBehaviour <- "mean.difference"
    
  }
  
  # If UncertaintyBehaviour is to randomly sample one state:
  if(UncertaintyBehaviour == "random") {
    
    # Find cells with uncertainties:
    UncertaintyCells <- grep("/", CladisticMatrix)
    
    # If there are uncertainties randomly sample one value and store:
    if(length(UncertaintyCells) > 0) CladisticMatrix[UncertaintyCells] <- unlist(lapply(as.list(CladisticMatrix[UncertaintyCells]), function(x) sample(strsplit(x, split = "/")[[1]], size = 1)))
    
    # Reset behaviour as mean difference to allow it to interact correctly with PolymorphismBehaviour later:
    UncertaintyBehaviour <- "mean.difference"
    
  }
  
  # If there are inapplicables and using the missing option then convert these to NAs:
  if(any(sort(CladisticMatrix == "")) && InapplicableBehaviour == "missing") CladisticMatrix[CladisticMatrix == ""] <- NA
  
  # Find all possible (symmetric) pairwise comparisons for the N taxa in the matrix (excluding self-comparisons):
  comparisons <- combn(1:nrow(CladisticMatrix), 2)
  
  # Find all comparable characters for each pair of taxa:
  list.of.compchar <- unlist(apply(comparisons, 2, GetComparableCharacters, CladisticMatrix), recursive = FALSE)
  
  # Get character states for each pairwise comparison:
  rows.pairs <- apply(comparisons, 2, GetPairwiseCharacterStrings, CladisticMatrix)
  
  # Subset each pairwise comparison by just the comparable characters:
  matrix.of.char.comp <- mapply(SubsetPairwiseByComparable, rows.pairs, list.of.compchar)
  
  # Deal with any polymorphisms found and collapse appropriately:
  matrix.of.char.comp <- mapply(EditPolymorphisms, unlist(apply(matrix.of.char.comp, 2, list), recursive = FALSE), list.of.compchar, MoreArgs = list(ordering, PolymorphismBehaviour, UncertaintyBehaviour))
  
  # Get the absolute differences between each comparable character for each pairwise comparison:
  diffs <- unlist(apply(matrix.of.char.comp, 2, GetAbsoluteCharacterDifferences), recursive = FALSE)
  
  # Correct distances for unordered characters where distance is greater than one:
  diffs <- mapply(CorrectForUnordered, diffs, list.of.compchar, MoreArgs = list(ordering))
  
  # If applying the Hopkins and St John Alpha approach:
  if(InapplicableBehaviour == "HSJ") {
    
    # Set primary-level characters in a list (where secondary etc. level characters will be added in turn):
    CharactersByLevel <- list(unname(setdiff(unique(CharacterDependencies[, "IndependentCharacter"]), unique(CharacterDependencies[, "DependentCharacter"]))))
    
    # Set starting more nested characters:
    HigherLevelCharacters <- setdiff(unique(c(CharacterDependencies)), unlist(CharactersByLevel))
    
    # Whilst there are still more nested levels of characters:
    while(length(HigherLevelCharacters) > 0) {
      
      # Add next level characters to characters by level list at next level:
      CharactersByLevel[[(length(CharactersByLevel) + 1)]] <- unname(CharacterDependencies[unlist(lapply(as.list(CharactersByLevel[[length(CharactersByLevel)]]), function(x) which(CharacterDependencies[, "IndependentCharacter"] == x))), "DependentCharacter"])
      
      # Set new higher level characters:
      HigherLevelCharacters <- setdiff(unique(c(CharacterDependencies)), unlist(CharactersByLevel))
      
    }
    
    # Update differences with HSJ alpha weights:
    # *** THIS IS THE LINE IT TRIGGERS
    diffs <- mapply(AlphaWeightingOfInapplicables, diffs, list.of.compchar, MoreArgs = list(ordering, weights, CharacterDependencies, CharactersByLevel, Alpha))
    
    # Reweight dependent characters zero:
    weights[unlist(CharactersByLevel[2:length(CharactersByLevel)])] <- 0
    
    # Update comparable characters by pruning out NAs:
    list.of.compchar <- mapply(function(x, y) y[!is.na(x)], x = diffs, y = list.of.compchar, SIMPLIFY = FALSE)
    
    # Update differences by pruning out NAs:
    diffs <- lapply(diffs, function(x) x[!is.na(x)])
    
  }
  
  # Weight differences:
  diffs <- mapply(WeightDifferences, diffs, list.of.compchar, MoreArgs = list(weights))
  
  # Get raw Euclidean distance (if using it):
  if(Distance == "RED") raw.dist <- lapply(diffs, RawEuclideanDistance)
  
  # Only calculate the max differences for "GED" or "MORD" matrices:
  if(Distance == "GED" || Distance == "MORD") {
    
    # Find maximum possible differences for the comparable characters:
    maxdiffs <- lapply(list.of.compchar, MaximumDIfferences, max.vals, min.vals)
    
    # Correct maximum differences for unordered characters:
    maxdiffs <- mapply(WeightDifferences, mapply(CorrectForUnordered, maxdiffs, list.of.compchar, MoreArgs = list(ordering)), list.of.compchar, MoreArgs = list(weights))
    
  }
  
  # If calculating Raw Euclidean Distances build the distance matrix:
  if(Distance == "RED") dist.matrix <- ConvertListToMatrix(raw.dist, CladisticMatrix)
  
  # If calculating the Gower Coefficient build the distance matrix:
  if(Distance == "GC") dist.matrix <- ConvertListToMatrix(as.list(mapply(CalculateGowerCoefficient, diffs, list.of.compchar, MoreArgs = list(weights))), CladisticMatrix)
  
  # If calculating the MORD build the distance matrix:
  if(Distance == "MORD") dist.matrix <- ConvertListToMatrix(mapply(CalculateMORD, diffs, maxdiffs), CladisticMatrix)
  
  # If calculating the GED:
  if(Distance == "GED") {
    
    # Build starting GED data:
    GED.data <- mapply(BuildStartingGEDData, diffs, list.of.compchar, MoreArgs = list(CladisticMatrix, weights), SIMPLIFY = FALSE)
    
    # Transpose matrices:
    GED.data <- lapply(GED.data, t)
    
    # Now build into matrix of pairwise comparisons (odds to be compared with adjacent evens):
    GED.data <- matrix(data = (unlist(GED.data)), ncol = ncol(CladisticMatrix), byrow = TRUE)
    
    # Calculate single weighted mean univariate distance for calculating GED Legacy or Hybrid (after equation 2 in Wills 2001):
    if(GEDType != "Wills") NonWills_S_ijk_bar <- rep(sum(unlist(diffs)) / sum(unlist(maxdiffs)), length.out = length(diffs))
    
    # Calculate individual pairwise weighted mean univariate distance for calculating GED Hybrid or Wills (after equation 2 in Wills 2001):
    if(GEDType != "Legacy") {
      
      # Generate individual mean pairwise distance for each comparison:
      NonLegacy_S_ijk_bar <- unlist(lapply(diffs, sum)) / unlist(lapply(maxdiffs, sum))
      
      # Find NaNs (divide by zero errors for when there are no characters in common in a pairwsie comparison):
      NaNs <- which(is.nan(NonLegacy_S_ijk_bar))
      
      # If usings WIlls version replace NaNs with NA:
      if(GEDType == "Wills" && length(NaNs) > 0) NonLegacy_S_ijk_bar[NaNs] <- NA
      
      # If using Hybrid replace NaNs with single global mean distance value:
      if(GEDType == "Hybrid" && length(NaNs) > 0) NonLegacy_S_ijk_bar[NaNs] <- NonWills_S_ijk_bar[NaNs]
      
      # Set modified non-Legacy S_ijk_bar as main S_ijk_bar:
      S_ijk_bar <- NonLegacy_S_ijk_bar
      
    }
    
    # If using Legacy set NonWills_S_ijk_bar as main S_ijk_bar:
    if(GEDType == "Legacy") S_ijk_bar <- NonWills_S_ijk_bar
    
    # For each set of differences:
    for(i in seq(from = 1, to = nrow(GED.data) - 1, length.out = length(diffs))) {
      
      # Find missing distances (if any):
      MissingDistances <- which(is.na(GED.data[i, ]))
      
      # Replace missing distances with S_ijk_bar (i.e., results of equation 2 in Wills 2001 into equation 1 of Wills 2001):
      if(length(MissingDistances) > 0) GED.data[i, MissingDistances] <- S_ijk_bar[ceiling(i / 2)]
      
    }
    
    # Isolate the distances:
    S_ijk <- GED.data[which((1:nrow(GED.data) %% 2) == 1), ]
    
    # Isolate the weights:
    W_ijk <- GED.data[which((1:nrow(GED.data) %% 2) == 0), ]
    
    # Calculate the GED (equation 1 of Wills 2001) for each pairwise comparison (ij):
    GED_ij <- sqrt(apply(W_ijk * (S_ijk ^ 2), 1, sum))
    
    # Create GED distance matrix:
    dist.matrix <- ConvertListToMatrix(as.list(GED_ij), CladisticMatrix)
    
  }
  
  # Build comparable characters matrix:
  comp.char.matrix <- ConvertListToMatrix(lapply(list.of.compchar, length), CladisticMatrix, diag = apply(CladisticMatrix, 1, CountCompleteCharacters))
  
  # Add row and column names (taxa) to distance matrices:
  rownames(dist.matrix) <- colnames(dist.matrix) <- rownames(comp.char.matrix) <- colnames(comp.char.matrix) <- rownames(CladisticMatrix)
  
  # If there are any NaNs replace with NAs:
  if(any(is.nan(dist.matrix))) dist.matrix[is.nan(dist.matrix)] <- NA
  
  # If using a proportional distance:
  if(Distance == "MORD" || Distance == "GC") {
    
    # If transforming distance matrix by taking the square root - take the square root:
    if(TransformDistances == "sqrt") dist.matrix <- sqrt(dist.matrix)
    
    # If transforming distance matrix by taking the arcsine square root:
    if(TransformDistances == "arcsine_sqrt") {
      
      # Check for squared distances greater than 1:
      if(any(sort(sqrt(dist.matrix)) > 1)) {
        
        # Warn user that distances were rescaled:
        print("Squared distances found of greater than 1 so matrix was rescaled prior to taking arcsine.")
        
        # Take the arcsine square root of the rescaled distance matrix:
        dist.matrix <- asin(sqrt(dist.matrix) / max(sort(sqrt(dist.matrix))))
        
        # If squared distances are less than or equal to one:
      } else {
        
        # Take the arcsine square root directly:
        dist.matrix <- asin(sqrt(dist.matrix))
        
      }
      
    }
    
  }
  
  # Compile results as a list:
  result <- list(Distance, dist.matrix, comp.char.matrix)
  
  # Add names to list:
  names(result) <- c("DistanceMetric", "DistanceMatrix", "ComparableCharacterMatrix")
  
  # Output result:
  return(result)
  
}